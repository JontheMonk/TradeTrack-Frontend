import XCTest
import Vision
import CoreImage
@testable import TradeTrack

final class FaceAnalyzerTests: XCTestCase {
    
    func testAnalyzeReturnsNilWhenDetectorFails() {
        let detector = MockDetector(result: nil)
        let validator = MockValidator(result: true)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        let result = sut.analyze(in: CIImage())
        XCTAssertNil(result)
    }

    func testAnalyzeReturnsNilWhenValidatorRejects() {
        let face = makeFace(roll: 0, yaw: 0)
        let detector = MockDetector(result: face)
        let validator = MockValidator(result: false)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        let result = sut.analyze(in: CIImage())
        XCTAssertNil(result)
    }

    func testAnalyzeReturnsFaceWhenDetectorAndValidatorSucceed() {
        let face = makeFace(roll: 0, yaw: 0)
        let detector = MockDetector(result: face)
        let validator = MockValidator(result: true)

        let sut = FaceAnalyzer(detector: detector, validator: validator)

        let result = sut.analyze(in: CIImage())
        XCTAssertEqual(result, face)
    }
}
