import CoreImage
import Vision

/// Core service that extracts a face embedding from a CIImage.
public protocol FaceEmbeddingExtracting {
    func embedding(from image: CIImage) throws -> FaceEmbedding
}


