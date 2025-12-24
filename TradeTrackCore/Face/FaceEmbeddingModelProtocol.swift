//
//  FaceEmbeddingModelProtocol.swift
//
//  Abstraction over the CoreML face-embedding model (InsightFace w600k_r50).
//  Allows the FaceEmbedder to depend on a protocol instead of a concrete
//  CoreML type, making the embedding pipeline fully mockable for tests.
//

import CoreML

/// Protocol representing a model capable of producing a face embedding
/// from a preprocessed 112×112 NCHW tensor.
///
/// This abstraction serves two purposes:
/// 1. **Testability** — Unit tests can provide a mock model that returns
///    controlled outputs without loading a CoreML model.
/// 2. **Flexibility** — Allows swapping models (different InsightFace versions,
///    quantized models, or future architectures) without touching `FaceEmbedder`.
///
/// The method mirrors the CoreML-generated model's `prediction` API.
///
/// ### Typical usage
/// ```swift
/// let output = try model.prediction(input: w600k_r50Input(input_1: array))
/// let features = output.featureValue(for: "683")?.multiArrayValue
/// ```
///
/// ### Mocking example
/// ```swift
/// final class MockEmbeddingModel: FaceEmbeddingModelProtocol {
///     var next: w600k_r50Output!
///
///     func prediction(input: w600k_r50Input) throws -> w600k_r50Output {
///         return next
///     }
/// }
/// ```
protocol FaceEmbeddingModelProtocol : Sendable {
    /// Runs the model on the given NCHW tensor.
    ///
    /// - Parameter input: The CoreML-generated input wrapper.
    /// - Returns: The CoreML output wrapper containing embedding features.
    /// - Throws: Any CoreML inference error.
    func prediction(input: w600k_r50_imageInput) async throws -> w600k_r50_imageOutput
}
