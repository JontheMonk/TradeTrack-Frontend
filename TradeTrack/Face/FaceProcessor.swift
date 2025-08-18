import Vision
import CoreImage

final class FaceProcessor {
    private let preprocessor: FacePreprocessor
    private let validator: FaceValidator
    private let embedder: FaceEmbedder

    init(
        preprocessor: FacePreprocessor = .init(),
        validator: FaceValidator = .init(),
        embedder: FaceEmbedder? = nil
    ) throws {
        self.preprocessor = preprocessor
        self.validator = validator
        self.embedder = try embedder ?? FaceEmbedder()
    }

    /// Preferred: process from an already-upright CIImage.
    func process(image: CIImage, face: VNFaceObservation) throws -> FaceEmbedding {
        try validator.validate(image: image, face: face)
        let preprocessed = try preprocessor.preprocessFace(image: image, face: face)
        return try embedder.embed(from: preprocessed)
    }
}
