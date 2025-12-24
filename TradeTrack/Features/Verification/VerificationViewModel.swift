import AVFoundation
import Vision
import SwiftUI
import TradeTrackCore
import Synchronization
import os.log

/// A ViewModel that manages the biometric verification pipeline.
///
/// This class coordinates between high-frequency camera frames, actor-based logic,
/// and backend verification using a thread-safe "Gatekeeper" pattern.
///
/// **Design Decisions:**
/// 1. **Atomic Gating:** Uses `Atomic<Bool>` to short-circuit frame processing on the background queue.
/// 2. **Actor Isolation:** Offloads stateful collection logic to the `FaceCollector` actor.
/// 3. **Task Cancellation:** Implements cooperative cancellation to prevent "Ghost UI" updates.
@MainActor
final class VerificationViewModel: NSObject, ObservableObject {

    // MARK: - Dependencies
    
    let camera: CameraManagerProtocol
    let processor: FaceProcessing
    let verifier: FaceVerificationProtocol
    let errorManager: ErrorHandling
    let logger = Logger(subsystem: "Jon.TradeTrack", category: "VerificationVM")
    
    /// The logic worker that handles the 0.8s "best-frame" window.
    let collector: FaceCollecting
    
    /// The computer vision analyzer. Marked `nonisolated` to allow background thread analysis.
    let analyzer: FaceAnalyzerProtocol

    // MARK: - Published UI State

    @Published var state: VerificationState = .detecting
    @Published var collectionProgress: Double = 0.0

    /// The unique identifier of the employee being verified.
    var targetEmployeeID: String?

    // MARK: - Task & Control Logic

    var task: Task<Void, Never>?
    let isProcessingFrame = Atomic<Bool>(false)
    #if DEBUG
    var uiTestObservers: [NSObjectProtocol] = []
    #endif

    // MARK: - Capture Delegate
    
    /// Bridges the background camera queue to the MainActor/Task pool.
    /// Uses an atomic load with `.relaxed` ordering for maximum throughput.
    private lazy var outputDelegate = VerificationOutputDelegate { [weak self] frame in
        guard let self = self, !self.isProcessingFrame.load(ordering: .relaxed) else { return }

        Task {
            guard let (face, quality) = await self.analyzer.analyze(in: frame) else {
                await self.handleNoFaceDetected()
                return
            }

            let result = await self.collector.process(face: face, image: frame, quality: quality)
            // on main thread
            await self.applyAnalysisResult(winner: result.winner, progress: result.progress)
        }
    }

    /// Updates the UI or triggers the verification task based on the collector's result.
    private func applyAnalysisResult(winner: (VNFaceObservation, CIImage)?, progress: Double) {
        if let winner = winner {
            self.collectionProgress = 0.0
            self.runVerificationTask(face: winner.0, image: winner.1)
        } else {
            self.collectionProgress = progress
        }
    }

    // MARK: - Init

    init(
        camera: CameraManagerProtocol,
        analyzer: FaceAnalyzerProtocol,
        collector: FaceCollecting,
        processor: FaceProcessing,
        verifier: FaceVerificationProtocol,
        errorManager: ErrorHandling,
        employeeId: String
    ) {
        self.camera = camera
        self.analyzer = analyzer
        self.collector = collector
        self.processor = processor
        self.verifier = verifier
        self.errorManager = errorManager
        self.targetEmployeeID = employeeId
        super.init()
    }
    
    deinit {
        #if DEBUG
        uiTestObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
    }

    // MARK: - Lifecycle

    var session: AVCaptureSession { camera.uiCaptureSession }

    func start() async {
        #if DEBUG
        installUITestSignalBridge()
        #endif
        do {
            try await camera.requestAuthorization()
            try await camera.start(delegate: outputDelegate)
        } catch {
            errorManager.showError(error)
        }
    }

    /// Stops the pipeline, cancels active tasks, and resets internal state.
    func stop() async {
        task?.cancel()
        task = nil
        
        isProcessingFrame.store(false, ordering: .relaxed)
        await collector.reset()
        await analyzer.reset()
        collectionProgress = 0.0
        
        await camera.stop()
        state = .detecting
    }

    // MARK: - Internal Handlers

    nonisolated func handleNoFaceDetected() async {
        // 1. Logic runs on the background (calling thread)
        if await collector.startTime != nil {
            await collector.reset()
            await analyzer.reset()
            
            await self.resetCollectionUI()
        }
    }

    private func resetCollectionUI() {
        self.collectionProgress = 0.0
    }

    func runVerificationTask(face: VNFaceObservation, image: CIImage) {
        self.isProcessingFrame.store(true, ordering: .relaxed)
        
        task = Task { [weak self] in // Inherits @MainActor from the ViewModel
            guard let self = self else { return }

            defer {
                self.isProcessingFrame.store(false, ordering: .relaxed)
                self.task = nil
            }

            do {
                try Task.checkCancellation()
                self.state = .processing

                let embedding = try await processor.process(image: image, face: face)
                
                try Task.checkCancellation()

                guard let employeeID = self.targetEmployeeID else {
                    throw AppError(code: .employeeNotFound)
                }
                
                try await verifier.verifyFace(employeeId: employeeID, embedding: embedding)

                if !Task.isCancelled {
                    self.state = .matched(name: employeeID)
                }
                
            } catch is CancellationError {
                logger.debug("Verification task cancelled by user.")
            } catch {
                if !Task.isCancelled {
                    self.logger.error("Verification error: \(error.localizedDescription)")
                    self.errorManager.showError(error)
                    self.state = .detecting
                } else {
                    self.logger.debug("Task failed but was cancelled, ignoring error.")
                }
            }
        }
    }
}
