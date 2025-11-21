@preconcurrency import AVFoundation
import Vision
import SwiftUI

/// High-level verification state for the UI.
/// - `detecting`: Camera is running, waiting for a valid face.
/// - `processing`: A face was found and is being analyzed + verified.
/// - `matched(name:)`: Backend confirmed identity.
enum VerificationState: Equatable {
    case detecting
    case processing
    case matched(name: String)
}

@MainActor
final class VerificationViewModel: NSObject, ObservableObject {

    // MARK: - Dependencies

    /// Manages the camera session (start, stop, authorization).
    private let camera: CameraManagerProtocol

    ///Runs Vision face detection + validation (roll/yaw/size/quality).
    private let analyzer: FaceAnalyzerProtocol

    ///Preprocesses + embeds the detected face for recognition.
    private let processor: FaceProcessor

    ///HTTP client for communicating with backend API.
    private let http: HTTPClient

    ///Centralized user-facing error presenter.
    private let errorManager: ErrorManager


    // MARK: - Published State

    /// Drives UI display (“Looking…”, “Processing…”, "Matched").
    @Published var state: VerificationState = .detecting

    /// The employee ID we expect to match against.
    var targetEmployeeID: String?


    // MARK: - Task & Timing Control

    /// The in-flight embed+verify pipeline.
    private var task: Task<Void, Never>?

    /// Throttles the frame rate so we don’t embed 60 images/sec.
    private var lastProcessedTime: Date?

    /// Minimum time between processed frames (seconds).
    private let minimumInterval: TimeInterval = 0.5


    // MARK: - Capture Delegate

    /// Called for each camera frame.
    /// Converts frames to CIImage and kicks off pipeline.
    private lazy var outputDelegate: VerificationOutputDelegate = {
        VerificationOutputDelegate { [weak self] frame in
            Task { @MainActor [weak self] in
                await self?.handle(frame)
            }
        }
    }()


    // MARK: - Init

    init(
        camera: CameraManagerProtocol,
        analyzer: FaceAnalyzerProtocol,
        processor: FaceProcessor,
        http: HTTPClient,
        errorManager: ErrorManager,
        employeeId: String
    ) {
        self.camera = camera
        self.analyzer = analyzer
        self.processor = processor
        self.http = http
        self.errorManager = errorManager
        self.targetEmployeeID = employeeId
        super.init()
    }


    // MARK: - Session Bridge for UI

    /// Exposes the underlying `AVCaptureSession` needed by SwiftUI's `CameraPreview`.
    ///
    /// Mocks are not expected here — this is UI-only code.
    var session: AVCaptureSession {
        guard let real = camera.session as? RealCaptureSession else {
            fatalError("UI attempted to use a mock session")
        }
        return real.uiSession
    }


    // MARK: - Lifecycle Control

    /// Requests camera authorization and starts session.
    func start() async {
        do {
            try await camera.requestAuthorization()
            try await camera.start(delegate: outputDelegate)
        } catch {
            errorManager.show(error)
        }
    }

    /// Stops the verification pipeline + camera.
    func stop() async {
        task?.cancel()
        task = nil
        await camera.stop()
        state = .detecting
        lastProcessedTime = nil
    }

    deinit { task?.cancel() }


    // MARK: - Frame Processing Pipeline (Throttled)

    /// Throttles frames and launches background recognition task.
    private func handle(_ image: CIImage) async {

        // --- Frame rate throttling ---
        let now = Date()
        if let last = lastProcessedTime,
           now.timeIntervalSince(last) < minimumInterval {
            return
        }
        lastProcessedTime = now

        // Only allow one recognition task at once.
        guard task == nil else { return }

        // Capture dependencies off the main actor.
        let analyzer = self.analyzer
        let processor = self.processor
        let http = self.http
        let employeeID = self.targetEmployeeID

        task = Task(priority: .userInitiated) { [weak self] in
            defer {
                Task { @MainActor [weak self] in
                    self?.task = nil
                }
            }

            do {
                // 1. Detect & validate face
                guard let face = analyzer.analyze(in: image) else { return }
                try Task.checkCancellation()

                // 2. Update UI to show processing
                await MainActor.run { self?.state = .processing }

                // 3. Embed the face
                let embedding = try processor.process(image: image, face: face)
                try Task.checkCancellation()

                // 4. Prepare and send backend verification request
                guard let employeeID else {
                    throw AppError(code: .employeeNotFound)
                }

                let req = VerifyFaceRequest(employeeId: employeeID, embedding: embedding)
                let _: Empty? = try await http.send(
                    "POST",
                    path: "verify-face",
                    body: req
                )

                // 5. Success
                await MainActor.run {
                    self?.state = .matched(name: employeeID)
                }

            } catch is CancellationError {
                await MainActor.run {
                    self?.state = .detecting
                }
            } catch {
                await MainActor.run {
                    self?.errorManager.show(error)
                    self?.state = .detecting
                }
            }
        }
    }
}
