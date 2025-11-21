import XCTest
import Vision
import CoreImage
@testable import TradeTrack

/// Unit tests for `FaceValidator`, which performs geometric and quality-based
/// filtering on detected faces before allowing them to pass to the embedding
/// stage.
///
/// These tests verify all major validation components:
///
/// ### 1. **Roll & Yaw Limits**
/// Ensures:
/// - Missing head pose values are rejected
/// - Excessive roll/yaw (beyond ±15°) are rejected
/// - Boundary values (exactly 15°) are accepted
/// - Slight exceedances are rejected
///
/// ### 2. **Face Size Requirements**
/// Ensures:
/// - Bounding boxes that are too small or degenerate are rejected
/// - Exactly-minimum-size boxes pass
/// - Wide/tall edge cases are handled consistently
///
/// ### 3. **Capture Quality Score**
/// Ensures:
/// - Scores below threshold (0.25) are rejected
/// - Exactly threshold is accepted
/// - NaN values are rejected
/// - Very high values remain accepted
/// - Provider-thrown errors result in rejection
///
/// ### 4. **Integrated Valid Case**
/// A fully valid face must pass all checks simultaneously.
///
/// These tests collectively ensure that the validator is robust and behaves
/// deterministically for all geometric/quality edge cases.
final class FaceValidatorTests: XCTestCase {

    private var validator = FaceValidator()

    // MARK: - Roll & Yaw

    /// Missing roll or yaw fields should automatically invalidate the face.
    func testRejectsMissingRollOrYaw() {
        let face = makeFace(roll: nil, yaw: 0)
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )
        XCTAssertFalse(result)
    }

    /// Rejects faces with excessive roll (40°).
    func testRejectsHighRoll() {
        let face = makeFace(
            roll: Float(40 * Double.pi / 180),
            yaw: 0
        )
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )
        XCTAssertFalse(result)
    }

    /// Rejects faces with excessive yaw (30°).
    func testRejectsHighYaw() {
        let face = makeFace(
            roll: 0,
            yaw: Float(30 * Double.pi / 180)
        )
        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.8 }
        )
        XCTAssertFalse(result)
    }

    /// Accepts a face with perfectly centered roll/yaw.
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

    /// Rejects faces whose normalized bounding box is below the minimum size threshold.
    func testRejectsFaceTooSmall() {
        let smallBox = CGRect(x: 0.2, y: 0.2, width: 0.1, height: 0.1)
        let face = makeFace(bbox: smallBox, roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }

    /// Accepts faces with sufficient bounding box area.
    func testAcceptsFaceSizeSufficient() {
        let box = CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        let face = makeFace(bbox: box, roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertTrue(result)
    }

    // MARK: - Capture Quality

    /// Rejects images with poor capture quality scores.
    func testRejectsLowCaptureQuality() {
        let face = makeFace(roll: 0, yaw: 0)

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in 0.1 }
        )

        XCTAssertFalse(result)
    }

    /// If the capture quality provider throws, the validator should reject the face.
    func testRejectsWhenQualityProviderThrows() {
        let face = makeFace(roll: 0, yaw: 0)

        let result = validator.isValid(
            face: face,
            in: CIImage(),
            captureQualityProvider: { _, _ in throw NSError(domain: "test", code: 1) }
        )

        XCTAssertFalse(result)
    }

    /// Accepts images with sufficient capture quality.
    func testAcceptsValidCaptureQuality() {
        let face = makeFace(roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.9 })
        XCTAssertTrue(result)
    }

    // MARK: - Fully Valid Case

    /// A face passing all roll/yaw/size/quality checks should be accepted.
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

    /// Missing yaw should trigger rejection.
    func testRejectsMissingYaw() {
        let face = makeFace(roll: 0, yaw: nil)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }

    /// Accepts roll exactly at threshold (15°).
    func testAcceptsRollExactlyAtThreshold() {
        let deg15 = Float(15 * Double.pi / 180)
        let face = makeFace(roll: deg15, yaw: 0)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertTrue(result)
    }

    /// Rejects roll slightly above threshold.
    func testRejectsRollJustAboveThreshold() {
        let deg = Float((15.1 * Double.pi) / 180)
        let face = makeFace(roll: deg, yaw: 0)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }

    /// Accepts yaw exactly at threshold (15°).
    func testAcceptsYawExactlyAtThreshold() {
        let deg15 = Float(15 * Double.pi / 180)
        let face = makeFace(roll: 0, yaw: deg15)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertTrue(result)
    }

    /// Rejects yaw slightly above threshold.
    func testRejectsYawJustAboveThreshold() {
        let deg = Float((15.1 * Double.pi) / 180)
        let face = makeFace(roll: 0, yaw: deg)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }

    // MARK: - Face Size Boundaries

    /// Accepts ROI exactly at minimum side length.
    func testAcceptsFaceAtExactMinSize() {
        let box = CGRect(x: 0.2, y: 0.2, width: 0.20, height: 0.20)
        let face = makeFace(bbox: box, roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertTrue(result)
    }

    /// Rejects ROI just under the minimum allowed size.
    func testRejectsFaceJustUnderMinSize() {
        let box = CGRect(x: 0.2, y: 0.2, width: 0.199, height: 0.199)
        let face = makeFace(bbox: box, roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }

    /// Rejects degenerate ROIs where one side is extremely thin.
    func testRejectsDegenerateBoundingBoxTallButNarrow() {
        let box = CGRect(x: 0.1, y: 0.1, width: 0.05, height: 0.9)
        let face = makeFace(bbox: box, roll: 0, yaw: 0)

        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.8 })
        XCTAssertFalse(result)
    }

    // MARK: - Capture Quality Boundaries

    /// Accepts capture quality exactly at the threshold (0.25).
    func testAcceptsQualityExactlyAtThreshold() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.25 })
        XCTAssertTrue(result)
    }

    /// Rejects capture quality just below threshold.
    func testRejectsQualityJustBelowThreshold() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 0.249 })
        XCTAssertFalse(result)
    }

    /// Rejects NaN capture quality because it provides no meaningful confidence.
    func testRejectsQualityNaN() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in Float.nan })
        XCTAssertFalse(result)
    }

    /// Accepts excessively high capture quality (upper-bounded only by positivity).
    func testAcceptsVeryHighQuality() {
        let face = makeFace(roll: 0, yaw: 0)
        let result = validator.isValid(face: face, in: CIImage(), captureQualityProvider: { _, _ in 10.0 })
        XCTAssertTrue(result)
    }
}
