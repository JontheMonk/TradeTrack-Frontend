import CoreVideo

protocol FaceEmbeddingProtocol: Sendable {
    /// Produces a normalized embedding from a preprocessed pixel buffer.
    func embed(from pixelBuffer: CVPixelBuffer) async throws -> FaceEmbedding
}
