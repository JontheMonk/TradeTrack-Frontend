@preconcurrency import AVFoundation
import Vision
import SwiftUI

enum VerificationState: Equatable { case detecting, processing, matched(name: String) }

@MainActor
final class VerificationViewModel: NSObject, ObservableObject {
    private let camera: CameraManaging
    private let analyzer: FaceAnalyzing
    private let processor: FaceProcessor
    private let http: HTTPClient
    private let errorManager: ErrorManager

    @Published var state: VerificationState = .detecting
    var targetEmployeeID: String?

    private var task: Task<Void, Never>?
    private var lastProcessedTime: Date?
    private let minimumInterval: TimeInterval = 0.5

    private lazy var outputDelegate: VerificationOutputDelegate = {
        VerificationOutputDelegate { [weak self] frame in
            Task { @MainActor [weak self] in
                await self?.handle(frame)
            }
        }
    }()

    init(
        camera: CameraManaging,
        analyzer: FaceAnalyzing,
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

    var session: AVCaptureSession {
        guard let real = camera.session as? RealCaptureSession else {
                fatalError("UI attempted to use a mock session")
            }
        return real.uiSession
    }

    func start() async {
        do {
            try await camera.requestAuthorization()
            try await camera.start(delegate: outputDelegate)
        } catch {
            errorManager.show(error)
        }
    }

    func stop() async {
        task?.cancel()
        task = nil
        await camera.stop()
        state = .detecting
        lastProcessedTime = nil
    }

    deinit { task?.cancel() }

    // MARK: - Throttled pipeline
    private func handle(_ image: CIImage) async {
        let currentTime = Date()
        if let lastTime = lastProcessedTime, currentTime.timeIntervalSince(lastTime) < minimumInterval {
            return
        }
        lastProcessedTime = currentTime

        guard task == nil else { return }

        // Snapshot deps off-main
        let employeeID = self.targetEmployeeID
        let analyzer = self.analyzer
        let processor = self.processor
        let http = self.http

        task = Task(priority: .userInitiated) { [weak self] in
            defer { Task { @MainActor [weak self] in self?.task = nil } }
            do {
                guard let face = analyzer.analyze(in: image) else {
                    return
                }

                try Task.checkCancellation()
                await MainActor.run { self?.state = .processing}
                let embedding = try processor.process(image: image, face: face)
                
                guard let employeeID else { throw AppError(code: .employeeNotFound) }
                let req = VerifyFaceRequest(employeeId: employeeID, embedding: embedding)
                
                try Task.checkCancellation()
                let _: Empty? = try await http.send("POST", path: "verify-face", body: req)

                await MainActor.run { self?.state = .matched(name: employeeID) }
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
