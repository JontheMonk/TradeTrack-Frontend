// VerificationViewModel.swift
import AVFoundation
import Vision
import SwiftUI

enum VerificationState: Equatable {
    case detecting
    case processing
    case matched(name: String)
}

final class VerificationViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // MARK: - Dependencies
    private let errorManager: ErrorManager
    private let cameraManager: CameraManager
    private let faceDetector: FaceDetector
    private let faceProcessor: FaceProcessor
    private let http: HTTPClient

    // MARK: - Properties
    var targetEmployeeID: String?
    @Published var verificationState: VerificationState = .detecting

    private var lastProcessed = Date(timeIntervalSince1970: 0)
    private let lastProcessedQueue = DispatchQueue(label: "lastProcessed.queue")
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
        self.cameraManager.setupCamera(delegate: self)
    }

    // MARK: - Session Control
    func getSession() -> AVCaptureSession { cameraManager.session }

    func stopSession() {
        faceProcessingTask?.cancel()
        faceProcessingTask = nil
        cameraManager.stop()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard faceProcessingTask == nil else { return } // avoid overlap
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        guard let face = faceDetector.detectFace(in: ciImage), shouldContinue() else { return }

        faceProcessingTask = Task(priority: .userInitiated) { [weak self] in
            defer { self?.faceProcessingTask = nil }
            guard let self else { return }

            await MainActor.run { self.verificationState = .processing }

            do {
                let embedding = try self.faceProcessor.process(ciImage, face: face)

                guard let employeeID = self.targetEmployeeID else {
                    // If you want "best match" without target, adapt your request/endpoint and drop this guard.
                    throw AppError(code: .unknown)
                }

                let req = embedding.toVerifyRequest(employeeId: employeeID)
                let result: VerifyFaceResponse? = try await self.http.send("POST", path: "verify-face", body: req)
                guard let result else { throw AppError(code: .invalidResponse) }

                // Prefer real name if your response has it; fallback to id.
                let displayName = result.employeeId

                await MainActor.run {
                    self.verificationState = .matched(name: displayName)
                }
            } catch {
                await MainActor.run {
                    self.errorManager.show(error)
                    self.verificationState = .detecting
                }
            }
        }
    }

    // MARK: - Helpers
    private func shouldContinue() -> Bool {
        lastProcessedQueue.sync {
            guard !Task.isCancelled else { return false }
            let now = Date()
            if now.timeIntervalSince(lastProcessed) > 1.5 {
                lastProcessed = now
                return true
            }
            return false
        }
    }
}
