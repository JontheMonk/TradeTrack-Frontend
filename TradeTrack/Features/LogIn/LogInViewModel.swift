import AVFoundation
import Vision
import SwiftUI

class LogInViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let cameraManager = CameraManager()
    private let faceDetector = FaceDetector()
    private let faceRecognitionManager: FaceRecognitionManager

    private var faceProcessingTask: Task<Void, Never>?
    private var lastProcessed = Date(timeIntervalSince1970: 0)

    @Published var faceDetected = false
    @Published var matchName: String? = nil

    override init() {
        do {
            self.faceRecognitionManager = try FaceRecognitionManager()
        } catch {
            fatalError("❌ Failed to initialize FaceRecognitionManager: \(error)")
        }

        super.init()
        cameraManager.setupCamera(delegate: self)
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
        guard let face = faceDetector.detectFace(in: ciImage) else {
            Task { @MainActor in self.faceDetected = false }
            return
        }
        
        guard shouldContinue() else { return }
        processFace(image: ciImage, face: face)

    }

    private func processFace(image: CIImage, face: VNFaceObservation) {
        withFaceProcessingTask {
            await MainActor.run { self.faceDetected = true }
            guard let embedding = self.prepareEmbedding(from: image, face: face) else { return }
            await self.handleRecognition(embedding)
        }

    }

    private func prepareEmbedding(from image: CIImage, face: VNFaceObservation) -> [Float]? {
        guard let preprocessed = faceRecognitionManager.preprocessFace(from: image, face: face) else { return nil }
        guard faceRecognitionManager.isFaceValid(pixelBuffer: preprocessed, face: face) else { return nil }
        return faceRecognitionManager.runModel(on: preprocessed)
    }

    

    private func handleRecognition(_ embedding: [Float]) async {
        do {
            if let name = try await faceRecognitionManager.matchFace(embedding: embedding),
               !Task.isCancelled {
                await MainActor.run {
                    self.matchName = name
                    self.cancelRecognition()
                }
            } else {
                print("❌ No match or view closed")
            }
        } catch {
            if !Task.isCancelled {
                print("❌ Match request failed: \(error)")
            }
        }
    }
    
    private func withFaceProcessingTask(_ body: @escaping () async -> Void) {
        faceProcessingTask = Task(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            defer { Task { @MainActor in self.faceProcessingTask = nil } }
            guard !Task.isCancelled else { return }

            await body()
        }
    }
    
    private func shouldContinue() -> Bool {
        guard !Task.isCancelled else { return false }
        guard Date().timeIntervalSince(lastProcessed) > 1.5 else { return false }
        lastProcessed = Date()
        return true
    }

}
