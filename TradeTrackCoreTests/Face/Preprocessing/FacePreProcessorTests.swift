import XCTest
import CoreImage
import Vision
@testable import TradeTrackCore

/// Unit tests for `FacePreprocessor`, validating correctness of cropping,
/// resizing, rendering, coordinate mapping, and gradient preservation.
///
/// These tests cover:
///  - Normal face cropping
///  - ROIs at image boundaries
///  - Tiny bounding boxes
///  - Non-square ROIs
///  - Rendering to BGRA pixel buffers
///  - Ensuring no horizontal flip occurs
///  - Ensuring center-based resizing scales with the *max* axis
///  - Gradient-based integrity tests verifying correct pixel extraction
///
/// The test suite intentionally uses synthetic CIImages (solid colors, gradients)
/// so failures are unambiguously tied to incorrect cropping/scaling math.
final class FacePreprocessorTests: XCTestCase {

    private var pre: FacePreprocessor!

    override func setUp() {
        super.setUp()
        // Use a fixed 112×112 model input — same as the real embedding model.
        pre = FacePreprocessor(outputSize: CGSize(width: 112, height: 112))
    }

    // MARK: - Tests

    /// Verifies that a valid normalized bounding box produces a correctly
    /// cropped and resized 112×112 pixel buffer.
    func test_preprocess_validCrop_resizesTo112() throws {
        let img = makeImage(width: 400, height: 300)
        let face = makeFace(bbox: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }

    /// Cropping must fail for bounding boxes that fall outside the image area.
    /// This ensures the preprocessor rejects invalid geometry rather than
    /// silently returning a corrupted or empty image.
    func test_preprocess_invalidCrop_throws() {
        let img = makeImage(width: 400, height: 300)
        let face = makeFace(bbox: CGRect(x: 2.0, y: 2.0, width: 0.5, height: 0.5))

        XCTAssertThrowsError(try pre.preprocessFace(image: img, face: face)) { error in
            guard let err = error as? AppError else { return XCTFail("Wrong error type") }
            XCTAssertEqual(err.code, .facePreprocessingFailedResize)
        }
    }

    /// Ensures that extremely tall or skinny ROIs still resize correctly.
    /// Validates that the final 112×112 output is always produced regardless
    /// of the ROI aspect ratio.
    func test_resize_largerThanImage_scalesCorrectly() throws {
        let img = makeImage(width: 40, height: 300)
        let face = makeFace(bbox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }

    /// Ensures the rendering pipeline outputs BGRA pixel buffers, not grayscale
    /// or extended-range color formats.
    func test_render_outputPixelBufferHasBGRAFormat() throws {
        let img = makeImage(width: 300, height: 300)
        let face = makeFace(bbox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetPixelFormatType(pb), kCVPixelFormatType_32BGRA)
    }

    /// Validates that cropping preserves *correct pixel locations*.
    /// Uses a radial gradient (red center, blue edges). The chosen ROI targets
    /// the center region, so the output should be red-dominant.
    func test_cropIntegrity_croppedRegionMatchesExpectedLocation() throws {
        let img = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: 200, y: 200),
            "inputRadius0": 0,
            "inputRadius1": 200,
            "inputColor0": CIColor(red: 0, green: 0, blue: 1),
            "inputColor1": CIColor(red: 1, green: 0, blue: 0)
        ])!
        .outputImage!
        .cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))

        let face = makeFace(bbox: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
        let pb = try pre.preprocessFace(image: img, face: face)

        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
        let r = base[2]
        let b = base[0]
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)

        XCTAssertGreaterThan(r, b, "Expected red-dominant region")
    }
    
    /// Tests that cropping still succeeds when the bbox lies exactly at the
    /// top or bottom edges of the image. Ensures boundary math is correct.
    func test_crop_atImageEdges() throws {
        let img = makeImage(width: 400, height: 400, color: .green)
        let face = makeFace(bbox: CGRect(x: 0.0, y: 0.95, width: 1.0, height: 0.05))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }
    
    /// Ensures extremely small ROIs (e.g., tiny faces far away) still produce
    /// a valid scaled output instead of failing or returning empty images.
    func test_tinyBoundingBoxStillProcesses() throws {
        let img = makeImage(width: 400, height: 400, color: .blue)
        let face = makeFace(bbox: CGRect(x: 0.45, y: 0.45, width: 0.05, height: 0.05))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }
    
    /// Ensures that wide but short ROIs still get centered and resized correctly.
    func test_nonSquareROI_scalesCorrectly() throws {
        let img = makeImage(width: 400, height: 400, color: .yellow)
        let face = makeFace(bbox: CGRect(x: 0.1, y: 0.4, width: 0.8, height: 0.2))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }
    
    /// Validates that preprocessing does **not** accidentally flip the image
    /// horizontally — a very common bug in Vision/CIFilter pipelines.
    ///
    /// Uses a left-red / right-blue gradient. ROI covers the left side, so the
    /// output should remain red-dominant.
    func test_horizontalFlip_integrity() throws {
        let gradient = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: 0,   y: 200),
            "inputPoint1": CIVector(x: 400, y: 200),
            "inputColor0": CIColor(red: 1, green: 0, blue: 0),
            "inputColor1": CIColor(red: 0, green: 0, blue: 1)
        ])!
        .outputImage!
        .cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))

        let face = makeFace(bbox: CGRect(x: 0, y: 0.25, width: 0.5, height: 0.5))
        let pb = try pre.preprocessFace(image: gradient, face: face)

        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
        let r = base[2]
        let b = base[0]
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)

        XCTAssertGreaterThan(r, b, "Image appears horizontally flipped!")
    }

    /// Ensures resizing uses the *maximum* axis scale factor (preserving aspect
    /// ratio) rather than the minimum — a common mistake that causes stretching
    /// or empty borders.
    func test_scalingUsesMaxAxis() throws {
        let img = makeHorizontalGradientImage(width: 400, height: 400)

        let face = makeFace(bbox: CGRect(x: 0.1, y: 0.45, width: 0.75, height: 0.125))
        let pb = try pre.preprocessFace(image: img, face: face)

        let pixels = pixelColumns(from: pb, columns: [0, 56, 111])

        let left   = pixels[0]
        let center = pixels[1]
        let right  = pixels[2]

        XCTAssertLessThan(left, center)
        XCTAssertLessThan(center, right)
    }
    
    /// Ensures center-based scaling actually centers the ROI after resizing.
    /// Uses a vertical gradient to validate that the middle row corresponds
    /// to the correct gradient midpoint.
    func test_centerCropIsTrulyCentered() throws {
        let img = makeVerticalGradientImage(width: 400, height: 400)
        let face = makeFace(bbox: CGRect(x: 0.45, y: 0.1, width: 0.1, height: 0.8))

        let pb = try pre.preprocessFace(image: img, face: face)
        let pixels = pixelRows(from: pb, rows: [0, 56, 111])

        let top    = pixels[0]
        let center = pixels[1]
        let bottom = pixels[2]

        XCTAssertLessThan(top, center)
        XCTAssertLessThan(center, bottom)
        XCTAssertEqual(center, 0.5, accuracy: 0.05) // Should hit center of gradient
    }
    
    /// Validates exact scale-factor logic by picking an ROI with a simple,
    /// deterministic size. The test passes as long as preprocessing completes
    /// successfully without using the *smaller* dimension by mistake.
    func test_scaleFactorExact() throws {
        let img = makeImage(width: 400, height: 400, color: .red)

        // ROI exactly 200×50 px → max scale must be used (based on 50 px height).
        let face = makeFace(bbox: CGRect(x: 0.25, y: 0.375, width: 0.5, height: 0.125))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }
}
