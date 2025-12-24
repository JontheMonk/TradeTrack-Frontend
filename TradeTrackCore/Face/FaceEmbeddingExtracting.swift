import CoreImage
import Vision

/// Core service that extracts a face embedding from a CIImage.
public protocol FaceEmbeddingExtracting: Sendable {
    func embedding(from image: CIImage) async throws -> FaceEmbedding
}


