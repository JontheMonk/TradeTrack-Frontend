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
    private let outputDelegate = VerificationOutputDelegate()

    init(http: HTTPClient, errorManager: ErrorManager, employeeId: String) {
        self.http = http
        self.errorManager = errorManager
        self.targetEmployeeID = employeeId
        super.init()

        outputDelegate.onFrame = { [weak self] frame in
            guard let self else { return }
            Task { @MainActor in
                await self.handle(frame)
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

    deinit { task?.cancel() }

    // MARK: - One-at-a-time pipeline
    private func handle(_ frame: FrameInput) async {
        guard task == nil else { return }

        // Snapshot values we need off-main
        let employeeID = self.targetEmployeeID
        let detector = self.detector
        let processor = self.processor
        let http = self.http

        state = .processing

        task = Task(priority: .userInitiated) { [weak self] in
            defer {
                Task { @MainActor [weak self] in self?.task = nil }
            }
            do {
                guard let face = detector.detectFace(in: frame.image) else {
                    await MainActor.run { self?.state = .detecting }
                    return
                }

                try Task.checkCancellation()

                // Embed off-main (structured child task; no detached)
                let embedding = try processor.process(frame, face: face)

                try Task.checkCancellation()

                guard let employeeID else { throw AppError(code: .employeeNotFound) }
                let req = embedding.toVerifyRequest(employeeId: employeeID)
                let _: Empty? = try await http.send("POST", path: "verify-face", body: req)

                await MainActor.run {
                    self?.state = .matched(name: employeeID)
                }
            } catch is CancellationError {
                await MainActor.run { self?.state = .detecting }
            } catch {
                await MainActor.run {
                    self?.errorManager.show(error)
                    self?.state = .detecting
                }
            }
        }
    }
}
