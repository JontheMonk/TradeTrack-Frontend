import AVFoundation
import Vision
import SwiftUI

enum VerificationState: Equatable { case detecting, processing, matched(name: String) }

@MainActor
final class VerificationViewModel: NSObject, ObservableObject {
    // deps
    private let camera = CameraManager()
    private let detector = FaceDetector()
    private let processor = try! FaceProcessor()
    private let http: HTTPClient
    private let errorManager: ErrorManager

    // ui
    @Published var state: VerificationState = .detecting
    var targetEmployeeID: String?

    // control
    private var task: Task<Void, Never>?
    private let outputDelegate: VerificationOutputDelegate

    init(http: HTTPClient, errorManager: ErrorManager, throttle: TimeInterval = 1.0) {
        self.http = http
        self.errorManager = errorManager
        self.outputDelegate = VerificationOutputDelegate(throttle: throttle)
        super.init()

        // Frame hookup: delegate -> VM
        outputDelegate.onFrame = { [weak self] sample in
            // We're on the camera frames queue here. Hop to MainActor to coordinate,
            // then offload heavy work inside a Task.
            Task { @MainActor [weak self] in
                await self?.handle(sample)
            }
        }
    }

    var session: AVCaptureSession { camera.session }

    func start() {
        Task {
            do {
                try await camera.requestAuthorization()
                try camera.start(delegate: outputDelegate)
            } catch {
                errorManager.show(error)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        camera.stop()
        state = .detecting
    }

    // MARK: - One-at-a-time pipeline
    private func handle(_ sampleBuffer: CMSampleBuffer) async {
        // If a previous frame is still being processed, skip.
        guard task == nil else { return }

        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let frame = FrameInput(buffer: pb, orientation: .leftMirrored)

        // Detect face on this exact frame (fast)
        guard let face = detector.detectFace(in: frame.image, orientation: frame.orientation) else { return }

        let http = self.http
        let employeeID = self.targetEmployeeID
        let processor = self.processor

        state = .processing

        task = Task(priority: .userInitiated) { [weak self] in
            defer {
                Task { @MainActor [weak self] in self?.task = nil }
            }
            do {
                let embedding = try await Task.detached(priority: .userInitiated) {
                    try processor.process(frame, face: face)
                }.value

                guard let employeeID else { throw AppError(code: .employeeNotFound) }
                let req = embedding.toVerifyRequest(employeeId: employeeID)
                let result: VerifyFaceResponse? = try await http.send("POST", path: "verify-face", body: req)
                guard let result else { throw AppError(code: .invalidResponse) }

                await MainActor.run {
                    self?.state = .matched(name: result.employeeId)
                }
            } catch is CancellationError {
                // ignore
            } catch {
                await MainActor.run {
                    self?.errorManager.show(error)
                    self?.state = .detecting
                }
            }
        }
    }
}
