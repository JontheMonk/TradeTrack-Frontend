import AVFoundation
import Vision
import SwiftUI

@MainActor
enum RecognitionState: Equatable {
    case detecting
    case processing
    case matched(name: String)
}

class FaceVerificationViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let cameraManager: CameraManager
    private let faceDetector: FaceDetector
    private let faceProcessor: FaceProcessor
    

    private var lastProcessed = Date(timeIntervalSince1970: 0)
    private let lastProcessedQueue = DispatchQueue(label: "lastProcessed.queue")

    @Published var recognitionState: RecognitionState = .detecting

    init(
        cameraManager: CameraManager = CameraManager(),
        faceDetector: FaceDetector = FaceDetector(),
        faceProcessor: FaceProcessor! = nil
    ) throws {
        self.cameraManager = cameraManager,
        self.faceDetector = faceDetector,
        self.faceProcessor = try faceProcessor ?? FaceProcessor()
        super.init()
        self.cameraManager.setupCamera(delegate: self)
    }


    func getSession() -> AVCaptureSession {
        self.cameraManager.session
    }

    func stopSession() {
       _cameraManager.stop()
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)


        guard let face = self.faceDetector.detectFace(in: ciImage),
              shouldContinue() else {
            return
        }

        runFaceProcessingTask {
            guard !Task.isCancelled else { return }

            await MainActor.run {
                recognitionState = .detecting
            }

            let result = self.faceProcessor.process(ciImage, face: face)
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
