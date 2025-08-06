import Vision
import CoreImage

final class FaceProcessor {
    private let preprocessor: FacePreprocessor
    private let validator: FaceValidator
    private let embedder: FaceEmbedder

    init(
        preprocessor: FacePreprocessor = FacePreprocessor(),
        validator: FaceValidator = FaceValidator(),
        embedder: FaceEmbedder? = nil
    ) throws {
        self.preprocessor = preprocessor
        self.validator = validator
        self.embedder = try embedder ?? FaceEmbedder()
    }


    func process(_ image: CIImage, face: VNFaceObservation) throws -> FaceEmbedding {
        let preprocessed = try preprocessor.preprocessFace(from: image, face: face)
        try validator.validate(buffer: preprocessed, face: face)
        return try embedder.embed(from: preprocessed)
    }
}
