import XCTest
import CoreML
import CoreVideo
@testable import TradeTrackCore

final class FaceEmbedderTests: XCTestCase {

    // MARK: - Helpers

    private func makeDummyPixelBuffer() -> CVPixelBuffer {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, 112, 112, kCVPixelFormatType_32BGRA, nil, &pb)
        return pb!
    }

    private func makeFakeOutput(count: Int) -> w600k_r50_imageOutput {
        let arr = try! MLMultiArray(shape: [NSNumber(value: count)], dataType: .float32)
        for i in 0..<count { arr[i] = NSNumber(value: Float(i)) }
        let dict: [String: MLFeatureValue] = ["683": MLFeatureValue(multiArray: arr)]
        return try! w600k_r50_imageOutput(features: MLDictionaryFeatureProvider(dictionary: dict))
    }

    // MARK: - Tests

    /// Verifies the embedder passes the pixel buffer directly to the model input
    func test_embed_passesBufferToModel() async throws {
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel)
        let pb = makeDummyPixelBuffer()
        
        mockModel.result = makeFakeOutput(count: 512)
        _ = try await sut.embed(from: pb)

        XCTAssertTrue(mockModel.lastInputBuffer === pb, "SUT should pass the buffer directly to the ML model input")
    }

    /// Verifies that model prediction errors are wrapped in .modelOutputMissing
    func test_embed_modelThrowsError_wrapsInAppError() async {
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel)
        mockModel.error = NSError(domain: "test", code: -1)

        do {
            _ = try await sut.embed(from: makeDummyPixelBuffer())
            XCTFail("Should have thrown")
        } catch {
            let appError = error as? AppError
            XCTAssertEqual(appError?.code, .modelOutputMissing)
        }
    }

    /// Verifies that missing expected feature keys ("683") throw .modelOutputMissing
    func test_embed_missingFeatureKey_throwsError() async {
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel)
        
        // Output with wrong key
        let dict: [String: MLFeatureValue] = ["wrong_key": MLFeatureValue(multiArray: try! MLMultiArray(shape: [1], dataType: .float32))]
        mockModel.result = try! w600k_r50_imageOutput(features: MLDictionaryFeatureProvider(dictionary: dict))

        do {
            _ = try await sut.embed(from: makeDummyPixelBuffer())
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual((error as? AppError)?.code, .modelOutputMissing)
        }
    }

    /// Verifies successful L2 normalization of the resulting vector
    func test_embed_returnsNormalizedEmbedding() async throws {
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel)
        
        // Provide a non-normalized fake vector [3.0, 4.0] (Magnitude = 5.0)
        let arr = try MLMultiArray(shape: [2], dataType: .float32)
        arr[0] = 3.0
        arr[1] = 4.0
        let dict: [String: MLFeatureValue] = ["683": MLFeatureValue(multiArray: arr)]
        mockModel.result = try w600k_r50_imageOutput(features: MLDictionaryFeatureProvider(dictionary: dict))

        let embedding = try await sut.embed(from: makeDummyPixelBuffer())

        // Normalized values should be [0.6, 0.8]
        XCTAssertEqual(embedding.values[0], 0.6, accuracy: 1e-5)
        XCTAssertEqual(embedding.values[1], 0.8, accuracy: 1e-5)
        
        // Total L2 Norm should be 1.0
        let norm = sqrt(embedding.values.reduce(0) { $0 + $1 * $1 })
        XCTAssertEqual(norm, 1.0, accuracy: 1e-5)
    }
}
