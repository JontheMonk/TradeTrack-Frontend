import XCTest
import CoreML
import CoreVideo
@testable import TradeTrackCore

/// Unit tests for `FaceEmbedder`, validating preprocessing, model invocation,
/// output extraction, and normalization behavior.
final class FaceEmbedderTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a dummy 112×112 BGRA pixel buffer for testing.
    /// This avoids needing real camera input.
    private func makeDummyPixelBuffer(width: Int = 112, height: Int = 112) -> CVPixelBuffer {
        var pb: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ]
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pb
        )
        return pb!
    }

    /// Creates a fake model output containing an embedding of the form
    /// `[0, 1, 2, ...]`, wrapped in the CoreML model output type.
    ///
    /// - Parameter count: Number of embedding dimensions.
    /// - Returns: A `w600k_r50Output` containing the fake embedding.
    private func makeFakeOutput(count: Int) -> w600k_r50Output {
        let arr = try! MLMultiArray(shape: [NSNumber(value: count)], dataType: .float32)
        for i in 0..<count {
            arr[i] = NSNumber(value: Float(i))
        }

        // Wrap in CoreML feature provider under the "683" key.
        let dict: [String: MLFeatureValue] = [
            "683": MLFeatureValue(multiArray: arr)
        ]

        return try! w600k_r50Output(features: MLDictionaryFeatureProvider(dictionary: dict))
    }

    /// Creates a model output explicitly *missing* the "683" embedding feature,
    /// used to ensure the embedder throws the correct `.modelOutputMissing` error.
    private func makeMissing683Output() -> w600k_r50Output {
        let empty = try! MLMultiArray(shape: [1], dataType: .float32)
        let dict: [String: MLFeatureValue] = [
            "someOtherOutput": MLFeatureValue(multiArray: empty)
        ]
        return try! w600k_r50Output(features: MLDictionaryFeatureProvider(dictionary: dict))
    }


    // MARK: - Tests

    /// Ensures the preprocessor is called exactly once and receives the correct pixel buffer.
    func test_embed_callsPreprocessor() throws {
        let mockPre = MockPreprocessor()
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel, preprocessor: mockPre)

        mockPre.result = try MLMultiArray(shape: [1,3,112,112], dataType: .float32)
        mockModel.result = makeFakeOutput(count: 512)

        let pb = makeDummyPixelBuffer()
        _ = try sut.embed(from: pb)

        XCTAssertEqual(mockPre.calls.count, 1)
        XCTAssertTrue(mockPre.calls.first === pb)
    }

    /// Ensures preprocessing failures propagate as `.facePreprocessingFailedRender`.
    func test_embed_preprocessingFailureThrowsCorrectError() {
        let mockPre = MockPreprocessor()
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel, preprocessor: mockPre)

        mockPre.error = NSError(domain: "x", code: -1)
        let pb = makeDummyPixelBuffer()

        XCTAssertThrowsError(try sut.embed(from: pb)) { err in
            guard let apperr = err as? AppError else { return XCTFail("Wrong error type") }
            XCTAssertEqual(apperr.code, .facePreprocessingFailedRender)
        }
    }

    /// Ensures the model receives exactly the NCHW array returned by the preprocessor.
    func test_embed_callsModelWithCorrectInput() throws {
        let mockPre = MockPreprocessor()
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel, preprocessor: mockPre)

        let nchw = try MLMultiArray(shape: [1,3,112,112], dataType: .float32)
        mockPre.result = nchw
        mockModel.result = makeFakeOutput(count: 512)

        let pb = makeDummyPixelBuffer()
        _ = try sut.embed(from: pb)

        XCTAssertEqual(mockModel.lastInputArray, nchw, "Model did not receive correct input MLMultiArray")
    }

    /// Ensures model prediction errors are surfaced as `.modelOutputMissing`.
    func test_embed_modelThrowsError() {
        let mockPre = MockPreprocessor()
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel, preprocessor: mockPre)

        mockPre.result = try? MLMultiArray(shape: [1,3,112,112], dataType: .float32)
        mockModel.error = NSError(domain: "x", code: -1)

        let pb = makeDummyPixelBuffer()

        XCTAssertThrowsError(try sut.embed(from: pb)) { err in
            guard let apperr = err as? AppError else { return XCTFail("Wrong type") }
            XCTAssertEqual(apperr.code, .modelOutputMissing)
        }
    }

    /// Ensures that if the model output does not contain the "683" feature,
    /// the embedder throws `.modelOutputMissing`.
    func test_embed_missingFeatureThrowsCorrectError() {
        let mockPre = MockPreprocessor()
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel, preprocessor: mockPre)

        mockPre.result = try? MLMultiArray(shape: [1,3,112,112], dataType: .float32)
        mockModel.result = makeMissing683Output()

        let pb = makeDummyPixelBuffer()

        XCTAssertThrowsError(try sut.embed(from: pb)) { err in
            guard let apperr = err as? AppError else { return XCTFail("Wrong type") }
            XCTAssertEqual(apperr.code, .modelOutputMissing)
        }
    }

    /// Ensures:
    ///  - Returned embeddings match the model output length
    ///  - Values are correctly L2-normalized
    ///  - Known indices normalize to expected values
    func test_embed_returnsCorrectEmbedding() throws {
        let mockPre = MockPreprocessor()
        let mockModel = MockEmbeddingModel()
        let sut = FaceEmbedder(model: mockModel, preprocessor: mockPre)

        mockPre.result = try MLMultiArray(shape: [1,3,112,112], dataType: .float32)

        // Fake embedding: [0, 1, 2, ...]
        mockModel.result = makeFakeOutput(count: 512)

        let pb = makeDummyPixelBuffer()
        let embedding = try sut.embed(from: pb)

        XCTAssertEqual(embedding.values.count, 512)

        // Ensure L2 norm is 1
        let norm = sqrt(embedding.values.reduce(0) { $0 + $1 * $1 })
        XCTAssertEqual(norm, 1.0, accuracy: 1e-5)

        // Validate a specific index normalization
        let raw: Float = 123
        let expected = raw / sqrt((0..<512).map { Float($0 * $0) }.reduce(0, +))
        XCTAssertEqual(embedding.values[123], expected, accuracy: 1e-6)
    }
    
    /// Ensures zero-vector embeddings remain zero instead of dividing by zero.
    func test_embeddingHandlesZeroVector() {
        let zero = [Float](repeating: 0, count: 512)
        let emb = FaceEmbedding(zero)

        XCTAssertEqual(emb.values, zero)
    }

}
