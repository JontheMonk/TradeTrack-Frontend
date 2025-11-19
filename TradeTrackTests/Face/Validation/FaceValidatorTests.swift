import XCTest
import Vision
import CoreImage
@testable import TradeTrack

final class FaceValidatorTests: XCTestCase {

    private var validator = FaceValidator()

    // MARK: - Roll & Yaw

    func testRejectsMissingRollOrYaw() {
        let face = makeFace(roll: nil, yaw: 0)
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )
        XCTAssertFalse(result)
    }

    func testRejectsHighRoll() {
        // roll 40 degrees
        let face = makeFace(
            roll: Float(40 * Double.pi/180),
            yaw: 0
        )
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )
        XCTAssertFalse(result)
    }

    func testRejectsHighYaw() {
        let face = makeFace(
            roll: 0,
            yaw: Float(30 * Double.pi/180)
        )
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )
        XCTAssertFalse(result)
    }

    func testAcceptsValidRollAndYaw() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )
        XCTAssertTrue(result)
    }

    // MARK: - Face Size

    func testRejectsFaceTooSmall() {
        let smallBox = CGRect(x: 0.2, y: 0.2, width: 0.1, height: 0.1)
        let face = makeFace(bbox: smallBox, roll: 0, yaw: 0)

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )

        XCTAssertFalse(result)
    }

    func testAcceptsFaceSizeSufficient() {
        let box = CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        let face = makeFace(bbox: box, roll: 0, yaw: 0)

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )

        XCTAssertTrue(result)
    }

    // MARK: - Capture Quality

    func testRejectsLowCaptureQuality() {
        let face = makeFace(roll: 0, yaw: 0)

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.1 } // too low
        )

        XCTAssertFalse(result)
    }

    func testRejectsWhenQualityProviderThrows() {
        let face = makeFace(roll: 0, yaw: 0)

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in
                throw NSError(domain: "test", code: 1)
            }
        )

        XCTAssertFalse(result)
    }

    func testAcceptsValidCaptureQuality() {
        let face = makeFace(roll: 0, yaw: 0)

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.9 }
        )

        XCTAssertTrue(result)
    }

    // MARK: - Fully Valid Case

    func testAcceptsValidFace() {
        let face = makeFace(
            bbox: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3),
            roll: 0,
            yaw: 0
        )

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.95 }
        )

        XCTAssertTrue(result)
    }
    
    // MARK: - Additional Roll & Yaw Edge Cases

    func testRejectsMissingYaw() {
        let face = makeFace(roll: 0, yaw: nil)
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )
        XCTAssertFalse(result)
    }

    func testAcceptsRollExactlyAtThreshold() {
        let deg15 = Float(15 * Double.pi / 180)
        let face = makeFace(roll: deg15, yaw: 0)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertTrue(result)
    }

    func testRejectsRollJustAboveThreshold() {
        let deg = Float((15.1 * Double.pi) / 180)
        let face = makeFace(roll: deg, yaw: 0)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }

    func testAcceptsYawExactlyAtThreshold() {
        let deg15 = Float(15 * Double.pi / 180)
        let face = makeFace(roll: 0, yaw: deg15)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertTrue(result)
    }

    func testRejectsYawJustAboveThreshold() {
        let deg = Float((15.1 * Double.pi) / 180)
        let face = makeFace(roll: 0, yaw: deg)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }
    
    // MARK: - Face Size Boundaries

    func testAcceptsFaceAtExactMinSize() {
        let box = CGRect(x: 0.2, y: 0.2, width: 0.20, height: 0.20)
        let face = makeFace(bbox: box, roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertTrue(result)
    }

    func testRejectsFaceJustUnderMinSize() {
        let box = CGRect(x: 0.2, y: 0.2, width: 0.199, height: 0.199)
        let face = makeFace(bbox: box, roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }

    func testRejectsDegenerateBoundingBoxTallButNarrow() {
        // Min side = 0.05 → should fail
        let box = CGRect(x: 0.1, y: 0.1, width: 0.05, height: 0.9)
        let face = makeFace(bbox: box, roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }
    
    // MARK: - Capture Quality Boundaries

    func testAcceptsQualityExactlyAtThreshold() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.25 }
        )
        XCTAssertTrue(result)
    }

    func testRejectsQualityJustBelowThreshold() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.249 }
        )
        XCTAssertFalse(result)
    }

    func testRejectsQualityNaN() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in Float.nan }
        )
        XCTAssertFalse(result)
    }

    func testAcceptsVeryHighQuality() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 10.0 } // Should still be valid
        )
        XCTAssertTrue(result)
    }

}
