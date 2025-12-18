import CoreML
@testable import TradeTrackCore

/// A test double for `FaceEmbeddingModelProtocol` used in `FaceEmbedder` unit tests.
///
/// This mock allows tests to:
///  - Inject a predetermined model output (`result`)
///  - Force the model call to throw an error (`error`)
///  - Inspect the exact `MLMultiArray` passed to the model (`lastInputArray`)
///
/// It does **not** perform any real ML inference. It simply returns or throws
/// based on the values set by the test.
final class MockEmbeddingModel: FaceEmbeddingModelProtocol {

    /// The fake output the mock will return if no error is set.
    /// Tests should assign a `w600k_r50Output` produced manually.
    var result: w600k_r50Output?

    /// If set, the mock will throw this error instead of returning `result`.
    var error: Error?

    /// Captures the last input tensor that was passed to `prediction(input:)`.
    /// Useful to assert that preprocessing produced the correct NCHW array.
    private(set) var lastInputArray: MLMultiArray?

    /// Mimics a real model prediction call.
    ///
    /// - Parameter input: The CoreML input wrapper containing the NCHW tensor.
    /// - Returns: The predetermined fake output (`result`), unless `error` is set.
    /// - Throws: `error` if provided.
    func prediction(input: w600k_r50Input) throws -> w600k_r50Output {
        // Record the passed input for test inspection.
        lastInputArray = input.input_1

        // If an error was injected, throw it.
        if let error { throw error }

        // Otherwise return the fake model output.
        return result!
    }
}
