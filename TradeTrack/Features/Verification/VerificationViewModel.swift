import AVFoundation
import Vision
import SwiftUI

enum VerificationState: Equatable {
    case detecting
    case processing
    case matched(name: String)
}

final class VerificationViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: - Deps
    private let errorManager: ErrorManager
    private let cameraManager: CameraManager
    private let faceDetector: FaceDetector
    private let faceProcessor: FaceProcessor
    private let http: HTTPClient

    // MARK: - UI
    @Published var verificationState: VerificationState = .detecting
    var targetEmployeeID: String?

    // MARK: - Control
    private var lastProcessed = Date(timeIntervalSince1970: 0)
    private var faceProcessingTask: Task<Void, Never>?

    // MARK: - Init
    init(
        errorManager: ErrorManager,
        cameraManager: CameraManager = CameraManager(),
        faceDetector: FaceDetector = FaceDetector(),
        http: HTTPClient,
        faceProcessor: FaceProcessor? = nil
    ) throws {
        self.errorManager = errorManager
        self.cameraManager = cameraManager
        self.faceDetector = faceDetector
        self.http = http
        self.faceProcessor = try faceProcessor ?? FaceProcessor()
        super.init()
        cameraManager.setupCamera(delegate: self)   // assume front cam, portrait, mirroring locked in CameraManager
    }

    // MARK: - Session
    func getSession() -> AVCaptureSession { cameraManager.session }

    func stopSession() {
        faceProcessingTask?.cancel()
        faceProcessingTask = nil
        cameraManager.stop()
    }

    // MARK: - Delegate
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // One task at a time + simple throttle
        guard faceProcessingTask == nil else { return }
        let now = Date()
        guard now.timeIntervalSince(lastProcessed) >= 1.5 else { return }
        lastProcessed = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Front camera, portrait, mirrored → .leftMirrored
        let frame = FrameInput(buffer: pixelBuffer, orientation: .leftMirrored)

        // Detect (landmarks-prepared face if your detector does that; otherwise keep as-is)
        guard let face = faceDetector.detectFace(in: frame.image, orientation: frame.orientation) else { return }

        faceProcessingTask = Task(priority: .userInitiated) { [weak self] in
            defer { self?.faceProcessingTask = nil }
            guard let self else { return }

            await MainActor.run { self.verificationState = .processing }

            do {
                let embedding = try self.faceProcessor.process(frame, face: face)

                guard let employeeID = self.targetEmployeeID else {
                    throw AppError(code: .employeeNotFound) // pick a better code if you have one
                }

                let req = embedding.toVerifyRequest(employeeId: employeeID)
                let result: VerifyFaceResponse? = try await self.http.send("POST", path: "verify-face", body: req)
                guard let result else { throw AppError(code: .invalidResponse) }

                await MainActor.run {
                    self.verificationState = .matched(name: result.employeeId)
                }
            } catch {
                await MainActor.run {
                    self.errorManager.show(error)
                    self.verificationState = .detecting
                }
            }
        }
    }
}
