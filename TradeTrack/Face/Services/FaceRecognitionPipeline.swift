import Vision
import CoreImage

enum FaceRecognitionResult {
    case matched(name: String)
    case timeout
    case failure(reason: String)
}

final class FaceRecognitionPipeline {
    private let detector: FaceDetector
    private let preprocessor: FacePreprocessor
    private let validator: FaceValidator
    private let embedder: FaceEmbedder
    private let api: FaceAPI

    init(detector: FaceDetector,
         preprocessor: FacePreprocessor,
         validator: FaceValidator,
         embedder: FaceEmbedder,
         api: FaceAPI) {
        self.detector = detector
        self.preprocessor = preprocessor
        self.validator = validator
        self.embedder = embedder
        self.api = api
    }

    func detectFace(in image: CIImage) -> VNFaceObservation? {
        detector.detectFace(in: image)
    }

    func process(_ image: CIImage, face: VNFaceObservation) async -> FaceRecognitionResult {
        guard let preprocessed = preprocessor.preprocessFace(from: image, face: face) else {
            return .failure(reason: "Preprocessing failed")
        }

        guard validator.passesValidation(buffer: preprocessed, face: face) else {
            return .failure(reason: "Face did not pass validation")
        }

        guard let embedding = try? embedder.embed(from: preprocessed) else {
            return .failure(reason: "Failed to generate embedding")
        }

        return await withTaskGroup(of: FaceRecognitionResult.self) { group in
            group.addTask {
                if let name = try? await self.api.matchFace(embedding: embedding),
                   !Task.isCancelled {
                    return .matched(name: name)
                }
                return .failure(reason: "No match")
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                return .timeout
            }

            let result = await group.first { _ in true } ?? .failure(reason: "Unknown error")
            group.cancelAll()
            return result
        }
    }
}
