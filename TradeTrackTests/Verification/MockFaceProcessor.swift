#if DEBUG
import Vision
import CoreImage
@testable import TradeTrackCore

/// A lightweight test double for the `FaceProcessing` capability.
///
/// `VerificationViewModel` and `RegisterViewModel` both depend on a concrete
/// implementation of `FaceProcessing` to turn a face into a normalized
/// embedding. In tests, we replace the real `FaceProcessor` with this mock
/// so we can:
///
///  • Control whether processing succeeds or throws
///  • Return a predictable, stable embedding
///  • Count how many times the pipeline was invoked
///
/// This avoids running Vision or CoreML during unit tests.
final class MockFaceProcessor: FaceProcessing, @unchecked Sendable {

    /// Number of times `process(image:face:)` was invoked.
    ///
    /// Useful for ensuring throttling, cancellation, and deduplication logic
    /// inside `VerificationViewModel`.
    private(set) var callCount = 0
    
    /// Captures the specific image passed into the processor.
    /// This allows tests to verify that the "Best Frame" was selected.
    private(set) var capturedImage: CIImage?

    /// The embedding the mock will return.
    ///
    /// Defaults to a normalized 512-vector of 0.5 values.
    /// Tests can override this with any embedding they want.
    var stubbedEmbedding = FaceEmbedding(
        Array(repeating: 0.5, count: 512)
    )

    /// Optional error to throw instead of returning an embedding.
    ///
    /// Set this to simulate Vision/ML failures.
    var stubbedError: Error?

    func process(image: CIImage, face: VNFaceObservation) throws -> FaceEmbedding {
        callCount += 1
        
        self.capturedImage = image
        
        if let error = stubbedError { throw error }
        return stubbedEmbedding
    }
}
#endif
