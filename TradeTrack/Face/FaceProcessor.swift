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


    func process(_ input: FrameInput, face: VNFaceObservation) throws -> FaceEmbedding {
        try validator.validate(frame: input, face: face)
        let preprocessed = try preprocessor.preprocessFace(from: input, face: face)
        return try embedder.embed(from: preprocessed)
    }
}
