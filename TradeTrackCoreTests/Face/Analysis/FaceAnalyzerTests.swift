import XCTest
import Vision
import CoreImage
@testable import TradeTrackCore

/// Unit tests for `FaceAnalyzer`, which coordinates:
///   1. Face detection (via `FaceDetectorProtocol`)
///   2. Face validation (via `FaceValidatorProtocol`)
///
/// The analyzer should:
///   - Return `nil` if *no face is detected*
///   - Return `nil` if the *validator rejects the face*
///   - Return the detected face only if *both* succeed
///
/// These tests use simple mocks with forced-return values so we
/// can isolate logic from Vision and real image processing.
final class FaceAnalyzerTests: XCTestCase {
    
    /// Ensures that if the detector returns `nil`, the analyzer
    /// does not proceed to validation and simply returns `nil`.
    ///
    /// This verifies the early-exit path and protects against
    /// regressions where optional faces might accidentally be
    /// force-unwrapped or validated incorrectly.
    func testAnalyzeReturnsNilWhenDetectorFails() {
        let detector = MockDetector(result: nil)
        let validator = MockValidator(result: true)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        let result = sut.analyze(in: CIImage())
        XCTAssertNil(result)
    }

    /// Ensures that even when a face *is* detected, the analyzer
    /// must still verify it using `FaceValidatorProtocol`.
    ///
    /// If the validator rejects the face (roll/yaw/size/quality),
    /// the analyzer must return `nil`.
    func testAnalyzeReturnsNilWhenValidatorRejects() {
        let face = makeFace(roll: 0, yaw: 0)
        let detector = MockDetector(result: face)
        let validator = MockValidator(result: false)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        let result = sut.analyze(in: CIImage())
        XCTAssertNil(result)
    }

    /// The happy path:
    ///  - Detector finds a face
    ///  - Validator accepts it
    ///  - Analyzer returns the same `VNFaceObservation`
    ///
    /// This verifies that no mutation or filtering happens to
    /// the face object and that the correct success branch is followed.
    func testAnalyzeReturnsFaceWhenDetectorAndValidatorSucceed() {
        let face = makeFace(roll: 0, yaw: 0)
        let detector = MockDetector(result: face)
        let validator = MockValidator(result: true)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        let result = sut.analyze(in: CIImage())
        XCTAssertEqual(result, face)
    }
}
