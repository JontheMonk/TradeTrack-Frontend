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

/// A ViewModel that manages the biometric verification pipeline.
///
/// This class coordinates between the camera stream, computer vision analysis,
/// and backend verification. It implements a "best-frame" collection strategy:
/// 1. It monitors frames for a valid face.
/// 2. It opens a 0.8s collection window to find the highest-quality image.
/// 3. It triggers immediate processing if a high-quality "perfect" frame is found.
@MainActor
final class VerificationViewModel: NSObject, ObservableObject {

    // MARK: - Dependencies

    private let camera: CameraManagerProtocol
    private let analyzer: FaceAnalyzerProtocol
    private let processor: FaceProcessing
    private let verifier: FaceVerificationProtocol
    private let errorManager: ErrorHandling
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "VerificationVM")

    // MARK: - Published UI State

    /// The current state of the verification process used to drive UI overlays.
    @Published var state: VerificationState = .detecting
    
    /// A value between 0.0 and 1.0 representing the progress of the current face collection window.
    /// Useful for animating scanning rings or progress bars.
    @Published var collectionProgress: Double = 0.0

    /// The unique identifier of the employee being verified.
    var targetEmployeeID: String?

    // MARK: - Task & Collection Control

    /// Holds the reference to the active asynchronous verification task.
    /// Used to prevent overlapping requests and manage cancellation.
    private var task: Task<Void, Never>?
    
    /// Stores the highest quality face metadata and image found in the current collection burst.
    private var bestCandidate: (observation: VNFaceObservation, image: CIImage, quality: Float)?
    
    /// The timestamp when the first valid face was detected for the current collection cycle.
    private var collectionStartTime: Date?
    
    /// The maximum amount of time (0.8s) to spend looking for a better frame before committing.
    private let collectionWindow: TimeInterval = 0.8
    
    /// The quality threshold (0.9) that triggers immediate verification, bypassing the remainder of the window.
    private let qualityHighWaterMark: Float = 0.9

    /// Storage for notification observers used during UI automation tests.
    private var uiTestObservers: [NSObjectProtocol] = []

    // MARK: - Capture Delegate

    /// Handles raw frames from the `CameraManager` and bridges them into the async processing pipeline.
    private lazy var outputDelegate = VerificationOutputDelegate { [weak self] frame in
        Task { @MainActor in
            await self?.handle(frame)
        }
    }

    // MARK: - Init

    /// Initializes the ViewModel with necessary biometric and networking services.
    /// - Parameters:
    ///   - camera: The manager handling the AVCaptureSession.
    ///   - analyzer: The service performing face detection and quality scoring.
    ///   - processor: The service generating vector embeddings from images.
    ///   - verifier: The service communicating with the backend API.
    ///   - errorManager: The centralized error reporting service.
    ///   - employeeId: The ID of the user to be verified.
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

    // MARK: - Session Bridge

    /// The active capture session used by the `VideoPreviewLayer`.
    var session: AVCaptureSession {
        return camera.uiCaptureSession
    }

    // MARK: - Lifecycle Control

    /// Starts the camera session and requests necessary permissions.
    func start() async {
        installUITestSignalBridgeIfNeeded()
        do {
            try await camera.requestAuthorization()
            try await camera.start(delegate: outputDelegate)
        } catch {
            errorManager.showError(error)
        }
    }

    /// Stops the camera session and cancels any in-flight verification tasks.
    func stop() async {
        task?.cancel()
        task = nil
        await camera.stop()
        resetCollection()
        state = .detecting
    }

    /// Resets the "best-frame" search metadata to initial values.
    private func resetCollection() {
        bestCandidate = nil
        collectionStartTime = nil
        collectionProgress = 0.0
    }

    deinit {
        for o in uiTestObservers {
            NotificationCenter.default.removeObserver(o)
        }
        task?.cancel()
    }

    // MARK: - Frame Processing Pipeline

    /// Evaluates a single camera frame for face presence and quality.
    ///
    /// If a face is found, it begins or continues a 0.8s collection window.
    /// If the face is lost, the window is reset.
    /// - Parameter image: The `CIImage` captured from the camera.
    private func handle(_ image: CIImage) async {
        // 1. Skip if a verification request is already in progress.
        guard task == nil else { return }

        // 2. Perform detection.
        guard let (face, quality) = analyzer.analyze(in: image) else {
            if collectionStartTime != nil { resetCollection() }
            return
        }

        let now = Date()

        // 3. Start window if this is the first frame.
        if collectionStartTime == nil {
            collectionStartTime = now
            logger.debug("Valid face detected. Starting collection window.")
        }

        // 4. Track the best frame.
        if quality > (bestCandidate?.quality ?? -1.0) {
            bestCandidate = (face, image, quality)
        }

        let timeElapsed = now.timeIntervalSince(collectionStartTime!)
        let isWindowFull = timeElapsed >= collectionWindow
        let isPerfectFace = quality >= qualityHighWaterMark
        
        collectionProgress = min(timeElapsed / collectionWindow, 1.0)

        // 5. Commit if window expires or a perfect face is found.
        if isWindowFull || isPerfectFace {
            guard let winner = bestCandidate else { return }
            
            let finalFace = winner.observation
            let finalImage = winner.image
            
            resetCollection()
            runVerificationTask(face: finalFace, image: finalImage)
        }
    }

    /// Launches a background task to process embeddings and verify them via the network.
    /// - Parameters:
    ///   - face: The vision observation containing face geometry.
    ///   - image: The image data to process.
    private func runVerificationTask(face: VNFaceObservation, image: CIImage) {
        let processor = self.processor
        let verifier = self.verifier

        task = Task(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            defer {
                Task { @MainActor in self.task = nil }
            }

            do {
                await MainActor.run { self.state = .processing }

                // 1. Generate local embedding.
                let embedding = try processor.process(image: image, face: face)
                try Task.checkCancellation()

                // 2. Verify with backend.
                guard let employeeID = self.targetEmployeeID else { throw AppError(code: .employeeNotFound) }
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

    // MARK: - UI Test Bridge

    /// Hooks into global notifications to allow UI tests to simulate camera events.
    private func installUITestSignalBridgeIfNeeded() {
        guard AppRuntime.mode == .uiTest, uiTestObservers.isEmpty else { return }

        let center = NotificationCenter.default

        uiTestObservers.append(center.addObserver(forName: .uiTestCameraNoFace, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.state = .detecting }
        })

        uiTestObservers.append(center.addObserver(forName: .uiTestCameraInvalidFace, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.state = .detecting
                self?.errorManager.showError(AppError(code: .faceConfidenceTooLow))
            }
        })

        uiTestObservers.append(center.addObserver(forName: .uiTestCameraValidFace, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.state = .matched(name: "Test User") }
        })
    }
}

// MARK: - Testing Extensions
#if DEBUG
extension VerificationViewModel {

    /// Simulates a frame entry and blocks until the background task is fully complete.
    func _test_runFrame(_ image: CIImage) async {
        await _test_handle(image)
        await _test_waitForTask()
    }

    /// Simulates a frame entry into the pipeline.
    func _test_handle(_ image: CIImage) async {
        await handle(image)
    }

    /// Suspends until the current verification task completes.
    func _test_waitForTask() async {
        let t = self.task
        await t?.value
    }
    
    /// Forces the collection window to end immediately using the current best candidate.
    func _test_forceCommit() {
        guard let winner = bestCandidate else { return }
        let finalFace = winner.observation
        let finalImage = winner.image
        resetCollection()
        runVerificationTask(face: finalFace, image: finalImage)
    }
    
    /// Exposes the internal task reference for state assertions in tests.
    var _test_task: Task<Void, Never>? {
        return self.task
    }
}
#endif
