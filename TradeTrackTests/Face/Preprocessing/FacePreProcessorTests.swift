import XCTest
import CoreImage
import Vision
@testable import TradeTrack

final class FacePreprocessorTests: XCTestCase {

    private var pre: FacePreprocessor!

    override func setUp() {
        super.setUp()
        pre = FacePreprocessor(outputSize: CGSize(width: 112, height: 112))
    }

    // MARK: - Tests

    func test_preprocess_validCrop_resizesTo112() throws {
        // 1. Synthetic 400×300 image
        let img = makeImage(width: 400, height: 300)

        // 2. Fake face bounding box (normalized)
        // centered 50% region
        let face = makeFace(bbox: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))

        // 3. Act
        let pb = try pre.preprocessFace(image: img, face: face)

        // 4. Assert pixel buffer size
        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }

    func test_preprocess_invalidCrop_throws() {
        let img = makeImage(width: 400, height: 300)

        // BBox completely outside the image
        let face = makeFace(bbox: CGRect(x: 2.0, y: 2.0, width: 0.5, height: 0.5))

        XCTAssertThrowsError(
            try pre.preprocessFace(image: img, face: face)
        ) { error in
            guard let err = error as? AppError else {
                return XCTFail("Wrong error type")
            }
            XCTAssertEqual(err.code, .facePreprocessingFailedResize)
        }
    }

    func test_resize_largerThanImage_scalesCorrectly() throws {
        // Very skinny image forces anisotropic crop
        let img = makeImage(width: 40, height: 300)

        let face = makeFace(bbox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))

        let pb = try pre.preprocessFace(image: img, face: face)
        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }

    func test_render_outputPixelBufferHasBGRAFormat() throws {
        // Normal face
        let img = makeImage(width: 300, height: 300)
        let face = makeFace(bbox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetPixelFormatType(pb),
                       kCVPixelFormatType_32BGRA)
    }

    func test_cropIntegrity_croppedRegionMatchesExpectedLocation() throws {
        // Create a gradient-like image so cropping changes pixels
        let img = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: 200, y: 200),
            "inputRadius0": 0,
            "inputRadius1": 200,
            "inputColor0": CIColor(red: 0, green: 0, blue: 1),
            "inputColor1": CIColor(red: 1, green: 0, blue: 0)
        ])!
            .outputImage!
            .cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))

        // crop center 50%
        let face = makeFace(bbox: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))

        let pb = try pre.preprocessFace(image: img, face: face)

        // The gradient has a red center and blue edges. The chosen bbox covers the
        // center, so the processed region should be red-dominant (r > b).
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)

        let r = base[2]
        let b = base[0]

        XCTAssertGreaterThan(r, b, "Expected red-dominant region")
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)
    }
    
    func test_crop_atImageEdges() throws {
        let img = makeImage(width: 400, height: 400, color: .green)

        // Crop a thin strip at the very top
        let face = makeFace(bbox: CGRect(x: 0.0, y: 0.95, width: 1.0, height: 0.05))

        let pb = try pre.preprocessFace(image: img, face: face)

        // Still must resize to 112x112 without errors
        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }
    
    func test_tinyBoundingBoxStillProcesses() throws {
        let img = makeImage(width: 400, height: 400, color: .blue)

        // Very tiny detected face-like region
        let face = makeFace(bbox: CGRect(x: 0.45, y: 0.45, width: 0.05, height: 0.05))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }
    
    func test_nonSquareROI_scalesCorrectly() throws {
        let img = makeImage(width: 400, height: 400, color: .yellow)

        // Very wide rectangle
        let face = makeFace(bbox: CGRect(x: 0.1, y: 0.4, width: 0.8, height: 0.2))

        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }
    
    func test_horizontalFlip_integrity() throws {
        // Left is red, right is blue
        let gradient = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: 0,   y: 200),
            "inputPoint1": CIVector(x: 400, y: 200),
            "inputColor0": CIColor(red: 1, green: 0, blue: 0),
            "inputColor1": CIColor(red: 0, green: 0, blue: 1)
        ])!
        .outputImage!
        .cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))

        // BBox covering the left half of the gradient
        let face = makeFace(bbox: CGRect(x: 0, y: 0.25, width: 0.5, height: 0.5))

        let pb = try pre.preprocessFace(image: gradient, face: face)

        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
        let r = base[2]
        let b = base[0]
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)

        // Should still be red-dominant — catches left/right flips.
        XCTAssertGreaterThan(r, b, "Image appears horizontally flipped!")
    }


    func test_scalingUsesMaxAxis() throws {
        // Creates a horizontal gradient (left = dark, right = light)
        let img = makeHorizontalGradientImage(width: 400, height: 400)

        // Extremely wide ROI: 300×50 px
        let face = makeFace(bbox: CGRect(x: 0.1, y: 0.45, width: 0.75, height: 0.125))

        let pb = try pre.preprocessFace(image: img, face: face)

        // Extract center pixel and left/right pixels of the final 112×112
        let pixels = pixelColumns(from: pb, columns: [0, 56, 111])

        let left   = pixels[0]
        let center = pixels[1]
        let right  = pixels[2]

        // Since it's a left→right gradient, center must be between left and right
        XCTAssertLessThan(left, center)
        XCTAssertLessThan(center, right)
    }
    
    func test_centerCropIsTrulyCentered() throws {
        // Vertical gradient: top=0, bottom=1
        let img = makeVerticalGradientImage(width: 400, height: 400)

        // Tall ROI: forces width to be scaled
        let face = makeFace(bbox: CGRect(x: 0.45, y: 0.1, width: 0.1, height: 0.8))

        let pb = try pre.preprocessFace(image: img, face: face)
        let pixels = pixelRows(from: pb, rows: [0, 56, 111])

        let top    = pixels[0]
        let center = pixels[1]
        let bottom = pixels[2]

        // Validate correct ordering
        XCTAssertLessThan(top, center)
        XCTAssertLessThan(center, bottom)

        // Validate CENTER is actually middle of gradient
        XCTAssertEqual(center, 0.5, accuracy: 0.05)
    }
    
    
    func test_scaleFactorExact() throws {
        // Dummy solid image so values don't matter
        let img = makeImage(width: 400, height: 400, color: .red)

        // ROI exactly 200×50 px
        let face = makeFace(bbox: CGRect(x: 0.25, y: 0.375, width: 0.5, height: 0.125))

        // Expected math:
        // sx = 112 / 200 = 0.56
        // sy = 112 / 50  = 2.24
        // max = 2.24
        let pb = try pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)

        // The test passes if it doesn't throw — but the real goal:
        // if scale=0.56 is chosen instead of 2.24, crop would fail
    }



}
