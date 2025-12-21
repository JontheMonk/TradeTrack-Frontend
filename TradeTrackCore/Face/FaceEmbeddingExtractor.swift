import CoreImage
import Vision

final class FaceEmbeddingExtractor: FaceEmbeddingExtracting {

    private let analyzer: FaceAnalyzerProtocol
    private let processor: FaceProcessing

    init(
        analyzer: FaceAnalyzerProtocol,
        processor: FaceProcessing
    ) {
        self.analyzer = analyzer
        self.processor = processor
    }

    func embedding(from image: CIImage) throws -> FaceEmbedding {
        guard let (face, _) = analyzer.analyze(in: image) else {
            throw AppError(code: .faceValidationFailed)
        }
        return try processor.process(image: image, face: face)
    }
}
