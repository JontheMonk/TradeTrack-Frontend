import CoreImage
import Vision

struct FaceEmbeddingExtractor: FaceEmbeddingExtracting {

    private let analyzer: FaceAnalyzerProtocol
    private let processor: FaceProcessing

    init(
        analyzer: FaceAnalyzerProtocol,
        processor: FaceProcessing
    ) {
        self.analyzer = analyzer
        self.processor = processor
    }

    func embedding(from image: CIImage) async throws -> FaceEmbedding {
        guard let (face, _) = await analyzer.analyze(in: image) else {
            throw AppError(code: .faceValidationFailed)
        }
        return try await processor.process(image: image, face: face)
    }
}
