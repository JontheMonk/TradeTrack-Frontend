import AVFoundation
import Vision
import SwiftUI

@MainActor
enum RecognitionState: Equatable {
    case idle
    case detecting
    case matched(name: String)
    case error(message: String)
    case timedOut
}

class LogInViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let cameraManager: CameraManager
    private let recognitionPipeline: FaceRecognitionPipeline

    private var faceProcessingTask: Task<Void, Never>?
    private var lastProcessed = Date(timeIntervalSince1970: 0)
    private let lastProcessedQueue = DispatchQueue(label: "lastProcessed.queue")

    @Published var recognitionState: RecognitionState = .idle

    init(
        cameraManager: CameraManager = CameraManager(),
        recognitionPipeline: FaceRecognitionPipeline = FaceRecognitionPipeline(
            detector: FaceDetector(),
            preprocessor: FacePreprocessor(),
            validator: FaceValidator(),
            embedder: try! FaceEmbedder(),
            api: FaceAPI()
        )
    ) {
        self.cameraManager = cameraManager
        self.recognitionPipeline = recognitionPipeline
        super.init()
        self.cameraManager.setupCamera(delegate: self)
    }

    func getSession() -> AVCaptureSession {
        cameraManager.session
    }

    func stopSession() {
        cameraManager.stop()
    }

    func cancelRecognition() {
        faceProcessingTask?.cancel()
        faceProcessingTask = nil
        stopSession()
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              faceProcessingTask == nil || faceProcessingTask?.isCancelled == true else {
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        guard let face = recognitionPipeline.detectFace(in: ciImage),
              shouldContinue() else {
            return
        }

        runFaceProcessingTask {
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.recognitionState = .detecting
            }

            let result = await self.recognitionPipeline.process(ciImage, face: face)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                switch result {
                case .matched(let name):
                    self.recognitionState = .matched(name: name)
                    self.cancelRecognition()
                case .timeout:
                    self.recognitionState = .timedOut
                case .failure(let reason):
                    self.recognitionState = .error(message: reason)
                }
            }
        }
    }

    private func runFaceProcessingTask(_ body: @escaping () async -> Void) {
        faceProcessingTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            defer {
                Task { @MainActor in self.faceProcessingTask = nil }
            }

            guard !Task.isCancelled else { return }
            await body()
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
