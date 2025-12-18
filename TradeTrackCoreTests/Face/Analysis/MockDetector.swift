import Vision
import CoreImage
@testable import TradeTrackCore

/// A trivial fake implementation of `FaceDetectorProtocol` used in tests.
///
/// This mock allows unit tests to control the detector’s output directly,
/// bypassing Vision entirely. By injecting a predetermined `VNFaceObservation`
/// (or `nil`), tests can cover analyzer logic deterministically without
/// relying on real image processing.
///
/// Typical usage:
///   - `result = nil` → simulate "no face detected"
///   - `result = someFace` → simulate successful detection
final class MockDetector: FaceDetectorProtocol {

    /// The face observation this mock should return when asked to detect.
    var result: VNFaceObservation?

    init(result: VNFaceObservation?) {
        self.result = result
    }

    /// Returns the preconfigured `result` regardless of input.
    ///
    /// - Parameter image: Ignored; included only for protocol conformance.
    /// - Returns: The injected `VNFaceObservation`, or `nil`.
    func detect(in image: CIImage) -> VNFaceObservation? {
        return result
    }
}
