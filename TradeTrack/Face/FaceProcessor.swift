import Vision
import CoreImage

final class FaceProcessor {
    private let preprocessor: FacePreprocessor
    private let embedder: FaceEmbedder

    init(preprocessor: FacePreprocessor,
         embedder: FaceEmbedder) {
        self.preprocessor = preprocessor
        self.embedder = embedder
    }

    func process(image: CIImage, face: VNFaceObservation) throws -> FaceEmbedding {
        let preprocessed = try preprocessor.preprocessFace(image: image, face: face)
        return try embedder.embed(from: preprocessed)
    }
}
