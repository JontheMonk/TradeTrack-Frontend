import AVFoundation
import Vision
import SwiftUI

@MainActor
enum VerificationState: Equatable {
    case detecting
    case processing
    case matched(name: String) // or use id if you don't have name
}

// Adjust to your real request/response models
struct VerifyFaceRequest: Encodable {
    let employeeId: String
    let embedding: [Double] // or [Float] depending on your app
}

struct FaceResult: Decodable {
    let employeeId: String
    let score: Double
}

class VerificationViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let errorManager: ErrorManager
    private let cameraManager: CameraManager
    private let faceDetector: FaceDetector
    private let faceProcessor: FaceProcessor
    private let http: HTTPClient

    // Set this from your UI when verifying a specific employee
    var targetEmployeeID: String?

    private var lastProcessed = Date(timeIntervalSince1970: 0)
    private let lastProcessedQueue = DispatchQueue(label: "lastProcessed.queue")

    @Published var recognitionState: VerificationState = .detecting

    init(
        errorManager: ErrorManager,
        cameraManager: CameraManager = CameraManager(),
        faceDetector: FaceDetector = FaceDetector(),
        http: HTTPClient = HTTPClient(baseURL: URL(string: "https://tradetrack-backend.onrender.com")!),
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

    func getSession() -> AVCaptureSession { cameraManager.session }
    func stopSession() { cameraManager.stop() }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        guard let face = faceDetector.detectFace(in: ciImage), shouldContinue() else { return }

        // Do async work off the capture callback
        Task {
            do {
                let embedding = try faceProcessor.process(ciImage, face: face) // produce [Double]/[Float]

                guard let employeeID = self.targetEmployeeID else {
                    // No target set; nothing to verify against
                    return
                }

                let req = VerifyFaceRequest(employeeId: employeeID, embedding: embedding.values) // adjust access

                // Wrapped JSON: success -> FaceResult?, error -> throws AppError already mapped
                let result: FaceResult? = try await http.send("POST", path: "verify-face", body: req)

                guard let result else {
                    throw AppError(code: .invalidResponse)
                }

                await MainActor.run {
                    // You only have employeeId + score; if you want name, either:
                    // 1) include name in FaceResult from backend, or
                    // 2) look up name by id here via another call.
                    self.recognitionState = .matched(name: result.employeeId)
                }

            } catch {
                await MainActor.run {
                    self.errorManager.show(error)
                }
            }
        }
    }

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
