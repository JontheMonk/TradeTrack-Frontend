import CoreVideo

public protocol FaceEmbeddingProtocol: AnyObject {
    /// Produces a normalized embedding from a preprocessed pixel buffer.
    func embed(from pixelBuffer: CVPixelBuffer) throws -> FaceEmbedding
}
