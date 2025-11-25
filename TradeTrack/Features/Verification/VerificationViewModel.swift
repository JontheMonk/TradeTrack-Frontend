@preconcurrency import AVFoundation
import Vision
import SwiftUI

/// High-level verification state for the UI.
///
/// - `detecting`: Camera is running, waiting for a valid face.
/// - `processing`: A valid face was detected and the app is now embedding it
///   + verifying it against the backend.
/// - `matched(name:)`: Verification succeeded for the provided employee ID.
enum VerificationState: Equatable {
    case detecting
    case processing
    case matched(name: String)
}

@MainActor
final class VerificationViewModel: NSObject, ObservableObject {

    // MARK: - Dependencies

    /// Provides access to the device camera through an abstraction layer.
    ///
    /// The real implementation owns:
    ///   - AVCaptureSession lifecycle
    ///   - authorization flow
    ///   - delivering frames to a delegate
    ///
    /// Tests can substitute `MockCameraManagerProtocol`.
    private let camera: CameraManagerProtocol

    /// Performs Vision face detection + validation checks:
    ///   - roll angle
    ///   - yaw angle
    ///   - bounding box size
    ///   - brightness/sharpness checks (if implemented)
    ///
    /// This ensures only *high-quality* faces go into the ML embedding model.
    private let analyzer: FaceAnalyzerProtocol

    /// Converts a validated face into a 512-dimensional normalized embedding.
    ///
    /// Internally wraps:
    ///   - cropping (FacePreprocessor)
    ///   - resizing
    ///   - BGRA buffer generation
    ///   - CoreML inference (FaceEmbedder)
    ///
    /// This is injected so it can be mocked in tests.
    private let processor: FaceProcessing

    /// Sends the embedding to the backend for identity verification.
    ///
    /// Using a dedicated protocol (`FaceVerificationProtocol`) allows
    /// clean unit tests with a simple mock.
    private let verifier: FaceVerificationProtocol

    /// Central UI error channel, decoupled via `ErrorHandling` protocol.
    private let errorManager: ErrorHandling


    // MARK: - Published UI State

    /// Drives the SwiftUI UI:
    ///   - "Looking for face…"
    ///   - "Processing…"
    ///   - "Matched: John Doe"
    @Published var state: VerificationState = .detecting

    /// The target employee ID that this camera session must verify.
    var targetEmployeeID: String?


    // MARK: - Task & Timing Control

    /// The in-flight verification task.
    ///
    /// Only *one* face may be processed at a time — this variable enforces that.
    /// When a task finishes (success, cancellation, or error), it sets itself to `nil`.
    private var task: Task<Void, Never>?

    /// Stores the timestamp of the last processed frame.
    ///
    /// Prevents the embedding model from running 60 times per second.
    private var lastProcessedTime: Date?

    /// Minimum allowed time between processed frames (in seconds).
    ///
    /// 0.5s = only 2 frames/sec max are processed.
    private let minimumInterval: TimeInterval = 0.5


    // MARK: - Capture Delegate

    /// Capture delegate that receives CIImages from the camera manager.
    ///
    /// Wrapped in a closure so we can easily inject `[weak self]` and ensure
    /// frame handling hops onto the `@MainActor`.
    private lazy var outputDelegate = VerificationOutputDelegate { [weak self] frame in
        Task { @MainActor in
            await self?.handle(frame)
        }
    }


    // MARK: - Init

    /// Creates a fully dependency-injected verification ViewModel.
    ///
    /// - Parameters:
    ///   - camera: Underlying camera manager.
    ///   - analyzer: Performs detection + validation.
    ///   - processor: Embeds the validated face.
    ///   - verifier: Talks to backend API.
    ///   - errorManager: Receives all user-facing errors.
    ///   - employeeId: Target backend employee ID to verify against.
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


    // MARK: - Session Bridge (UI Only)

    /// Exposes the real `AVCaptureSession` to SwiftUI's `CameraPreview`.
    ///
    /// - Important:
    ///   This intentionally fails if a mock camera is used in UI previews,
    ///   because previews should not load camera infrastructure.
    var session: AVCaptureSession {
        guard let real = camera.session as? RealCaptureSession else {
            fatalError("UI attempted to use a mock session")
        }
        return real.uiSession
    }


    // MARK: - Lifecycle Control

    /// Begins the verification process:
    ///   1. Request camera permissions
    ///   2. Start the camera session
    ///   3. Begin receiving frames → handled by `outputDelegate`
    func start() async {
        do {
            try await camera.requestAuthorization()
            try await camera.start(delegate: outputDelegate)
        } catch {
            errorManager.showError(error)
        }
    }

    /// Completely resets the state and stops the camera.
    func stop() async {
        task?.cancel()
        task = nil
        await camera.stop()
        state = .detecting
        lastProcessedTime = nil
    }

    deinit {
        task?.cancel()
    }


    // MARK: - Frame Processing Pipeline

    /// Main pipeline invoked for each incoming frame.
    ///
    /// Steps:
    /// -----------------------------------------------------
    /// 1. Throttle frames (avoid 60 embeddings/sec)
    /// 2. Ensure only one verification task runs at once
    /// 3. Run face detection
    /// 4. Switch UI to `.processing`
    /// 5. Run embedding
    /// 6. Send verification request
    /// 7. Update UI to `.matched` on success
    /// -----------------------------------------------------
    ///
    /// All long-running work happens in a background `Task`.
    private func handle(_ image: CIImage) async {

        // --- (1) Frame-rate throttling ---
        let now = Date()
        if let last = lastProcessedTime,
           now.timeIntervalSince(last) < minimumInterval {
            return        // Too soon → skip this frame
        }
        lastProcessedTime = now

        // --- (2) Only one recognition task at a time ---
        guard task == nil else { return }

        // Capture everything we need off the main actor:
        let analyzer = self.analyzer
        let processor = self.processor
        let verifier = self.verifier
        let employeeID = self.targetEmployeeID   // may become nil if VM reused

        // --- Start async pipeline ---
        task = Task(priority: .userInitiated) { [weak self] in
            // Always clear task reference when finished.
            defer {
                Task { @MainActor [weak self] in
                    self?.task = nil
                }
            }

            do {
                // --- (3) Detect & validate face ---
                guard let face = analyzer.analyze(in: image) else { return }
                try Task.checkCancellation()

                // --- (4) Switch UI to .processing ---
                await MainActor.run { self?.state = .processing }

                // --- (5) Embed the face ---
                let embedding = try processor.process(image: image, face: face)
                try Task.checkCancellation()

                // --- (6) Backend verification ---
                guard let employeeID else {
                    throw AppError(code: .employeeNotFound)
                }

                try await verifier.verifyFace(
                    employeeId: employeeID,
                    embedding: embedding
                )

                // --- (7) Success ---
                await MainActor.run {
                    self?.state = .matched(name: employeeID)
                }

            } catch is CancellationError {
                // Expected cancellation → reset UI.
                await MainActor.run {
                    self?.state = .detecting
                }

            } catch {
                // Any real failure → show banner + reset state.
                await MainActor.run {
                    self?.errorManager.showError(error)
                    self?.state = .detecting
                }
            }
        }
    }
}
#if DEBUG
extension VerificationViewModel {

    /// Triggers the private frame-handling pipeline and waits for the
    /// background verification task to finish. This provides a clean,
    /// deterministic testing surface without touching AVFoundation.
    func _test_runFrame(_ image: CIImage) async {
        await _test_handle(image)
        await _test_waitForTask()
    }

    /// Directly calls the private `handle(_:)` method.
    /// Allows tests to simulate a new camera frame.
    func _test_handle(_ image: CIImage) async {
        await handle(image)
    }

    /// Awaits completion of the in-flight verification task.
    /// Necessary because `handle(_:)` launches its work
    /// inside a background `Task` that does **not** block the caller.
    func _test_waitForTask() async {
        let t = self.task
        await t?.value
    }
}
#endif

