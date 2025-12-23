import AVFoundation
import Vision
import SwiftUI
import TradeTrackCore
import os.log

/// Defines the high-level states of the face verification lifecycle.
enum VerificationState: Equatable {
    /// The system is actively searching for a valid face in the camera feed.
    case detecting
    /// A face has been captured; the system is generating embeddings and communicating with the server.
    case processing
    /// Verification was successful for the specified employee.
    case matched(name: String)
}

/// A ViewModel that manages the biometric verification pipeline by coordinating
/// between the camera, the face collector logic, and the backend verifier.
@MainActor
final class VerificationViewModel: NSObject, ObservableObject {

    // MARK: - Dependencies
    
    let camera: CameraManagerProtocol
    let processor: FaceProcessing
    let verifier: FaceVerificationProtocol
    let errorManager: ErrorHandling
    let logger = Logger(subsystem: "Jon.TradeTrack", category: "VerificationVM")
    
    /// The logic worker that handles the 0.8s "best-frame" window.
    let collector = FaceCollector()
    
    /// The computer vision analyzer. Marked `nonisolated` to allow background thread analysis.
    nonisolated let analyzer: FaceAnalyzerProtocol

    // MARK: - Published UI State

    @Published var state: VerificationState = .detecting
    @Published var collectionProgress: Double = 0.0

    /// The unique identifier of the employee being verified.
    var targetEmployeeID: String?

    // MARK: - Task & Control Logic

    var task: Task<Void, Never>?
    let isProcessingFrame = AtomicBool()
    var uiTestObservers: [NSObjectProtocol] = []

    // MARK: - Capture Delegate
    
    /// Bridges the background camera queue to the MainActor.
    private lazy var outputDelegate = VerificationOutputDelegate { [weak self] frame in
        guard let self = self, !self.isProcessingFrame.value else { return }

        // 1. BACKGROUND: Vision Analysis
        guard let (face, quality) = await self.analyzer.analyze(in: frame) else {
            Task { @MainActor in self.handleNoFaceDetected() }
            return
        }

        // 2. BACKGROUND: Collection Logic (Async call to our Actor)
        Task {
            // We do the logic work here on a background thread
            let possibleWinner = await self.collector.process(face: face, image: frame, quality: quality)
            let currentProgress = await self.collector.progress

            // 3. MAIN ACTOR: Only hop once to update UI
            await MainActor.run {
                self.collectionProgress = currentProgress
                
                if let winner = possibleWinner {
                    self.runVerificationTask(face: winner.0, image: winner.1)
                }
            }
        }
    }

    // MARK: - Init

    init(
        camera: CameraManagerProtocol,
        analyzer: FaceAnalyzerProtocol,
        processor: FaceProcessing,
        verifier: FaceVerificationProtocol,
        errorManager: ErrorHandling,
        employeeId: String
    ) {
        self.camera = camera
        self.analyzer = analyzer
        self.processor = processor
        self.verifier = verifier
        self.errorManager = errorManager
        self.targetEmployeeID = employeeId
        super.init()
    }

    // MARK: - Lifecycle

    var session: AVCaptureSession { camera.uiCaptureSession }

    func start() async {
        installUITestSignalBridge()
        do {
            try await camera.requestAuthorization()
            try await camera.start(delegate: outputDelegate)
        } catch {
            errorManager.showError(error)
        }
    }

    func stop() async {
        task?.cancel()
        task = nil
        
        await collector.reset()
        await analyzer.reset()
        collectionProgress = 0.0
        
        await camera.stop()
        state = .detecting
    }

    // MARK: - Internal Handlers

    func handleNoFaceDetected() async {
        if collector.startTime != nil {
            await collector.reset()
            await analyzer.reset()
            collectionProgress = 0.0
        }
    }

    func runVerificationTask(face: VNFaceObservation, image: CIImage) {
        self.isProcessingFrame.value = true
        self.collectionProgress = 0.0
        
        task = Task(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            defer {
                Task { @MainActor in
                    self.task = nil
                    self.isProcessingFrame.value = false
                }
            }

            do {
                await MainActor.run { self.state = .processing }

                // Generate local biometric embedding
                let embedding = try processor.process(image: image, face: face)
                try Task.checkCancellation()

                // Verify with backend
                guard let employeeID = self.targetEmployeeID else {
                    throw AppError(code: .employeeNotFound)
                }
                try await verifier.verifyFace(employeeId: employeeID, embedding: embedding)

                await MainActor.run { self.state = .matched(name: employeeID) }
            } catch {
                self.logger.error("Verification error: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorManager.showError(error)
                    self.state = .detecting
                }
            }
        }
    }
}
