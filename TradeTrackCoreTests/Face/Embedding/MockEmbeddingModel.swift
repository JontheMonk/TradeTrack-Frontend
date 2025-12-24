import CoreML
@testable import TradeTrackCore

final class MockEmbeddingModel: FaceEmbeddingModelProtocol, @unchecked Sendable {
    var result: w600k_r50_imageOutput?
    var error: Error?

    /// Captures the pixel buffer passed to the model
    private(set) var lastInputBuffer: CVPixelBuffer?

    func prediction(input: w600k_r50_imageInput) async throws -> w600k_r50_imageOutput {
        // Record the buffer for test inspection
        lastInputBuffer = input.input_1

        if let error = error { throw error }
        
        guard let result = result else {
            fatalError("Mock result not set")
        }
        return result
    }
}
