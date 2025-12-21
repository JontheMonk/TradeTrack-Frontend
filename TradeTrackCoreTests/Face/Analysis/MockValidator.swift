import Vision
import CoreImage
@testable import TradeTrackCore

/// A simple fake implementation of `FaceValidatorProtocol` for unit tests.
///
/// This mock bypasses all real validation logic (roll/yaw checks, size checks,
/// capture quality, etc.) and simply returns the boolean you configure.
/// It allows tests to force the analyzer down either the “accept” or “reject”
/// path without touching Vision or CIImage internals.
///
/// Typical usage:
///   - `result = true`  → simulate a valid, high-quality face
///   - `result = false` → simulate validator rejecting the face
final class MockValidator: FaceValidatorProtocol {

    /// The value returned by `isValid(...)` regardless of input.
    var result: Bool

    init(result: Bool) {
        self.result = result
    }

    /// Returns the preconfigured `result` and ignores all other inputs.
    ///
    /// - Parameters:
    ///   - face: Ignored.
    ///   - quality: Ignored
    /// - Returns: Whatever `result` is set to.
    func isValid(
        face: VNFaceObservation,
        quality : Float
    ) -> Bool {
        return result
    }
}
