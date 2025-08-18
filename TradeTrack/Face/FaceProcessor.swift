import Vision
import CoreImage

final class FaceProcessor {
    private let preprocessor: FacePreprocessor
    private let validator: FaceValidator
    private let embedder: FaceEmbedder

    init(preprocessor: FacePreprocessor,
         validator: FaceValidator,
         embedder: FaceEmbedder) {
        self.preprocessor = preprocessor
        self.validator = validator
        self.embedder = embedder
    }

    // Convenience: build the defaults, can throw
    convenience init() throws {
        try self.init(preprocessor: .init(),
                      validator: .init(),
                      embedder: FaceEmbedder())
    }

    func process(image: CIImage, face: VNFaceObservation) throws -> FaceEmbedding {
        try validator.validate(image: image, face: face)
        let preprocessed = try preprocessor.preprocessFace(image: image, face: face)
        return try embedder.embed(from: preprocessed)
    }
}
