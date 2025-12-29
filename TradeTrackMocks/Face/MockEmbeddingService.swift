import UIKit
import TradeTrackCore

/// Test double for `RegistrationEmbeddingServing`.
///
/// This mock replaces the real face-embedding pipeline (Vision → preprocessing → CoreML)
/// with a predictable, fully synchronous implementation.
///
/// It allows `RegisterViewModel` tests to:
///   • simulate successful face embedding generation
///   • simulate embedding failures
///   • assert how many times embedding was requested
///   • avoid running any ML or Vision code (which is too slow and nondeterministic for unit tests)
///
/// The mock exposes two test-controlled outputs:
///   • `stubbedEmbedding` — returned whenever embedding succeeds
///   • `stubbedError` — thrown instead of generating an embedding
///
/// The ViewModel under test depends only on the protocol, so injecting this mock
/// keeps the tests isolated, fast, and deterministic.
@MainActor
final class MockEmbeddingService: RegistrationEmbeddingServing {

    /// Number of times the ViewModel attempted to request an embedding.
    ///
    /// Useful for verifying that:
    ///   • the ViewModel triggers embedding exactly once per submission
    ///   • duplicate submissions do *not* call into the embedding pipeline again
    private(set) var callCount = 0

    /// The embedding returned when no error is injected.
    ///
    /// This is a normalized 512-dimensional vector, matching the real model output shape.
    /// Tests may override this to verify that the embedding is forwarded correctly
    /// into the `EmployeeInput` sent to the backend.
    var stubbedEmbedding = FaceEmbedding(
        Array(repeating: 0.5, count: 512)
    )

    /// Optional error to simulate embedding failure.
    ///
    /// When set, `embedding(from:)` will throw this error instead of returning a vector.
    /// This allows ViewModel tests to verify proper error handling and UI messaging.
    var stubbedError: Error?

    /// Returns the stubbed embedding or throws a stubbed error.
    ///
    /// - Parameter image: Ignored in this mock (the real service would analyze face data).
    /// - Returns: The `stubbedEmbedding` when no error is present.
    /// - Throws: `stubbedError`, if provided.
    func embedding(from image: UIImage) throws -> FaceEmbedding {
        callCount += 1
        if let error = stubbedError { throw error }
        return stubbedEmbedding
    }
}
