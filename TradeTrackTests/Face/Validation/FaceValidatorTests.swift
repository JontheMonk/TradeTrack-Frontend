import XCTest
import Vision
import CoreImage
@testable import TradeTrack

final class FaceValidatorTests: XCTestCase {

    private var validator: FaceValidator!

    override func setUp() {
        super.setUp()
        validator = FaceValidator()
    }

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
        let face = makeFace(roll: 0, yaw: 0, boundingBox: smallBox)

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )

        XCTAssertFalse(result)
    }

    func testAcceptsFaceSizeSufficient() {
        let box = CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        let face = makeFace(roll: 0, yaw: 0, boundingBox: box)

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
            roll: 0,
            yaw: 0,
            boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        )

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.95 }
        )

        XCTAssertTrue(result)
    }
}
