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
    
    /// The computer vision analyzer. Marked `nonisolated` to allow background thread analysis
    /// without hopping to the MainActor for every raw camera frame.
    nonisolated private let analyzer: FaceAnalyzerProtocol
    
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
    
    /// An atomic flag synchronized between the background camera queue and the @MainActor.
    /// Prevents redundant Vision analysis while a verification request is in flight.
    private let isProcessingFrame = AtomicBool()
    
    /// A thread-safe bridge between the background camera queue and the MainActor.
    ///
    /// The `isProcessingFrame` flag (AtomicBool) prevents the background queue from
    /// flooding the MainActor with processing requests while a network task is active.
    private lazy var outputDelegate = VerificationOutputDelegate { [weak self] frame in
        guard let self = self else { return }

        // 1. Thread-safe check: Are we already in a verification task?
        guard !self.isProcessingFrame.value else { return }

        // 2. BACKGROUND ANALYSIS: Run Vision scoring here (off the Main Thread)
        // Heavy lifting occurs nonisolated to maintain high frame rates.
        guard let (face, quality) = self.analyzer.analyze(in: frame) else {
            // If no face found, we must communicate to the VM to reset its window.
            Task { @MainActor in self.handleNoFaceDetected() }
            return
        }

        // 3. ONLY HOP TO MAIN if we have a valid face to process
        Task { @MainActor in
            self.handle(face: face, image: frame, quality: quality)
        }
    }

    // MARK: - Init

    /// Initializes the ViewModel with necessary biometric and networking services.
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

    /// Stops the camera session and cleans up the verification lifecycle.
    ///
    /// This method performs a comprehensive teardown:
    /// 1. **Cancellation:** Aborts active async tasks (network or ML).
    /// 2. **State Reset:** Clears "best-frame" candidates and resets analyzer metadata.
    /// 3. **Hardware Control:** Shuts down the `AVCaptureSession` to save power.
    /// 4. **UI Update:** Reverts the state to `.detecting`.
    ///
    /// - Note: Should be called when the view disappears or the user exits the flow.
    func stop() async {
        task?.cancel()
        task = nil
        
        analyzer.reset()
        resetCollection()
        
        await camera.stop()
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
    /// This method manages the "Best-Frame" collection window:
    /// - **Windowing:** On first detection, a 0.8s timer starts.
    /// - **Candidate Selection:** Tracks the highest quality frame seen during the window.
    /// - **Short-Circuit:** If quality exceeds `qualityHighWaterMark` (0.9), it triggers immediately.
    /// - **Reset:** If the face is lost, the current window is discarded.
    ///
    /// - Parameters:
    ///   - face: Vision metadata for the detected face.
    ///   - image: The raw buffer from the camera.
    ///   - quality: A pre-calculated score (0.0 - 1.0) indicating clarity and pose.
    private func handle(face: VNFaceObservation, image: CIImage, quality: Float) {
        guard task == nil else { return }

        let now = Date()

        if collectionStartTime == nil {
            collectionStartTime = now
        }

        if quality > (bestCandidate?.quality ?? -1.0) {
            bestCandidate = (face, image, quality)
        }

        let timeElapsed = now.timeIntervalSince(collectionStartTime!)
        collectionProgress = min(timeElapsed / collectionWindow, 1.0)

        if timeElapsed >= collectionWindow || quality >= qualityHighWaterMark {
            guard let winner = bestCandidate else { return }
            
            // Lock the atomic flag for the duration of the network task
            self.isProcessingFrame.value = true
            
            resetCollection()
            runVerificationTask(face: winner.observation, image: winner.image)
        }
    }

    /// Terminates the current collection window when face tracking is lost.
    ///
    /// Ensures that if a user pulls away and returns, the system begins a fresh
    /// 0.8s window rather than committing to a stale, low-quality frame.
    private func handleNoFaceDetected() {
        if collectionStartTime != nil {
            resetCollection()
            analyzer.reset()
        }
    }

    /// Executes the heavy-lift biometric verification sequence.
    ///
    /// 1. Switches UI to `.processing`.
    /// 2. Generates local biometric embeddings via ML.
    /// 3. Performs backend identity verification.
    ///
    /// - Note: Supports Swift Concurrency cancellation. If `stop()` is called,
    ///   embedding generation and network calls will abort.
    /// - Important: The `isProcessingFrame` flag is reset in `defer` to ensure
    ///   the camera feed resumes even on failure.
    private func runVerificationTask(face: VNFaceObservation, image: CIImage) {
        let processor = self.processor
        let verifier = self.verifier

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

    /// Simulates a frame entry into the pipeline by first passing it through the analyzer.
    func _test_handle(_ image: CIImage) async {
        if let (face, quality) = self.analyzer.analyze(in: image) {
            self.handle(face: face, image: image, quality: quality)
        } else {
            self.handleNoFaceDetected()
        }
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
    
    var _test_collectionStartTime: Date? {
        return self.collectionStartTime
    }
}
#endif
