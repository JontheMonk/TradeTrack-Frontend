import CoreML
import CoreVideo

/// A test double for `PixelPreprocessorProtocol`, used to simulate the
/// image → NCHW preprocessing step in `FaceEmbedder` tests.
///
/// This mock allows tests to:
///  - Inject a predetermined NCHW tensor (`result`)
///  - Inject an error to simulate preprocessing failures (`error`)
///  - Inspect every pixel buffer passed into the preprocessor (`calls`)
///
/// It performs no real cropping, resizing, or color work — it's purely
/// an inspection and control mechanism for unit tests.
final class MockPreprocessor: PixelPreprocessorProtocol {

    /// The fake NCHW MLMultiArray to return when preprocessing succeeds.
    /// Tests should assign this before calling `toNCHW`.
    var result: MLMultiArray?

    /// If set, `toNCHW` throws this error immediately.
    var error: Error?
    
    /// A record of all pixel buffers passed into the preprocessor.
    /// Useful for asserting correct call counts and parameters.
    private(set) var calls: [CVPixelBuffer] = []

    /// Errors specific to this mock's behavior.
    enum MockPreprocessorError: Error {
        /// Thrown when no `result` has been set and no explicit error is provided.
        case resultNotSet
    }

    /// Returns the predetermined `result`, or throws an injected error.
    ///
    /// - Parameter pixelBuffer: The image buffer to preprocess.
    /// - Returns: The mocked NCHW tensor if available.
    /// - Throws:
    ///   - `error` if it has been set
    ///   - `MockPreprocessorError.resultNotSet` if no result was provided
    func toNCHW(pixelBuffer: CVPixelBuffer) throws -> MLMultiArray {
        // Log call for assertion in tests
        calls.append(pixelBuffer)

        // Simulate thrown error
        if let error { throw error }

        // Ensure the test configured a fake NCHW output
        guard let result else { throw MockPreprocessorError.resultNotSet }

        return result
    }
}
