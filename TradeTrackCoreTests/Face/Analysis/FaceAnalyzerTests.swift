import XCTest
import Vision
import CoreImage
@testable import TradeTrackCore
@testable import TradeTrackMocks

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
    func testAnalyzeReturnsNilWhenDetectorFails() async {
        // Updated: Pass nil for face. Quality is irrelevant if face is nil.
        let detector = MockDetector(resultFace: nil, resultQuality: 0.0)
        let validator = MockValidator(result: true)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        let result = await sut.analyze(in: CIImage())
        XCTAssertNil(result)
    }

    /// Ensures that even when a face *is* detected, the analyzer
    /// must still verify it using `FaceValidatorProtocol`.
    func testAnalyzeReturnsNilWhenValidatorRejects() async {
        let face = makeFace(roll: 0, yaw: 0)
        // Updated: Detector succeeds, but validator will fail.
        let detector = MockDetector(resultFace: face, resultQuality: 0.5)
        let validator = MockValidator(result: false)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        let result = await sut.analyze(in: CIImage())
        XCTAssertNil(result)
    }

    func testAnalyzeReturnsFaceAndQualityWhenDetectorAndValidatorSucceed() async {
        // Arrange
        let expectedFace = makeFace(roll: 0, yaw: 0)
        let expectedQuality: Float = 0.85
        
        let detector = MockDetector(resultFace: expectedFace, resultQuality: expectedQuality)
        let validator = MockValidator(result: true)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        // Act
        let result = await sut.analyze(in: CIImage())

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.0, expectedFace)
        XCTAssertEqual(result?.1, expectedQuality)
    }
}
