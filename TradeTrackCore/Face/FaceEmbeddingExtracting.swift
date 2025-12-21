import CoreImage
import Vision

/// Core service that extracts a face embedding from a CIImage.
public protocol FaceEmbeddingExtracting {
    func embedding(from image: CIImage) throws -> FaceEmbedding
}

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
        guard let face = analyzer.analyze(in: image) else {
            throw AppError(code: .faceValidationFailed)
        }
        return try processor.process(image: image, face: face)
    }
}
