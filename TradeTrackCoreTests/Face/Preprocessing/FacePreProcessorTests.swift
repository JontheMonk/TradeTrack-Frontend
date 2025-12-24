import XCTest
import CoreImage
import Vision
@testable import TradeTrackCore

final class FacePreprocessorTests: XCTestCase {

    private var pre: FacePreprocessor!

    override func setUp() {
        super.setUp()
        // Initialize the actor with the standard model input size
        pre = FacePreprocessor(outputSize: CGSize(width: 112, height: 112))
    }

    // MARK: - Tests

    func test_preprocess_validCrop_resizesTo112() async throws {
        let img = makeImage(width: 400, height: 300)
        let face = makeFace(bbox: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))

        let result = try await pre.preprocessFace(image: img, face: face)
        let pb = result.buffer

        XCTAssertEqual(CVPixelBufferGetWidth(pb), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(pb), 112)
    }

    func test_preprocess_invalidCrop_throws() async {
        let img = makeImage(width: 400, height: 300)
        let face = makeFace(bbox: CGRect(x: 2.0, y: 2.0, width: 0.5, height: 0.5))

        do {
            _ = try await pre.preprocessFace(image: img, face: face)
            XCTFail("Should have thrown for out-of-bounds bbox")
        } catch {
            guard let err = error as? AppError else {
                return XCTFail("Expected AppError, got \(type(of: error))")
            }
            XCTAssertEqual(err.code, .facePreprocessingFailedResize)
        }
    }

    func test_resize_largerThanImage_scalesCorrectly() async throws {
        let img = makeImage(width: 40, height: 300)
        let face = makeFace(bbox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))

        let result = try await pre.preprocessFace(image: img, face: face)
        
        XCTAssertEqual(CVPixelBufferGetWidth(result.buffer), 112)
        XCTAssertEqual(CVPixelBufferGetHeight(result.buffer), 112)
    }

    func test_render_outputPixelBufferHasBGRAFormat() async throws {
        let img = makeImage(width: 300, height: 300)
        let face = makeFace(bbox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4))

        let result = try await pre.preprocessFace(image: img, face: face)

        XCTAssertEqual(CVPixelBufferGetPixelFormatType(result.buffer), kCVPixelFormatType_32BGRA)
    }

    func test_cropIntegrity_croppedRegionMatchesExpectedLocation() async throws {
        let img = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: 200, y: 200),
            "inputRadius0": 0,
            "inputRadius1": 200,
            "inputColor0": CIColor(red: 0, green: 0, blue: 1), // Blue center
            "inputColor1": CIColor(red: 1, green: 0, blue: 0)  // Red outer
        ])!.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))

        // Crop the very center (the blue part)
        let face = makeFace(bbox: CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2))
        let result = try await pre.preprocessFace(image: img, face: face)
        let pb = result.buffer

        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
        let b = base[0] // BGRA -> 0 is Blue
        let r = base[2] // BGRA -> 2 is Red
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)

        XCTAssertGreaterThan(b, r, "Expected blue-dominant center region")
    }

    func test_horizontalFlip_integrity() async throws {
        let gradient = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: 0,   y: 200),
            "inputPoint1": CIVector(x: 400, y: 200),
            "inputColor0": CIColor(red: 1, green: 0, blue: 0), // Red Left
            "inputColor1": CIColor(red: 0, green: 0, blue: 1)  // Blue Right
        ])!.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))

        // Crop the left half
        let face = makeFace(bbox: CGRect(x: 0, y: 0.25, width: 0.5, height: 0.5))
        let result = try await pre.preprocessFace(image: gradient, face: face)
        let pb = result.buffer

        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
        let r = base[2]
        let b = base[0]
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)

        XCTAssertGreaterThan(r, b, "Image appears horizontally flipped! Left should be red.")
    }

    func test_scalingUsesMaxAxis() async throws {
        let img = makeHorizontalGradientImage(width: 400, height: 400)
        let face = makeFace(bbox: CGRect(x: 0.1, y: 0.45, width: 0.75, height: 0.125))
        
        let result = try await pre.preprocessFace(image: img, face: face)
        let pb = result.buffer
        
        let pixels = pixelColumns(from: pb, columns: [0, 56, 111])
        XCTAssertLessThan(pixels[0], pixels[1])
        XCTAssertLessThan(pixels[1], pixels[2])
    }

    func test_centerCropIsTrulyCentered() async throws {
        let img = makeVerticalGradientImage(width: 400, height: 400)
        let face = makeFace(bbox: CGRect(x: 0.45, y: 0.1, width: 0.1, height: 0.8))

        let result = try await pre.preprocessFace(image: img, face: face)
        let pixels = pixelRows(from: result.buffer, rows: [0, 56, 111])

        XCTAssertGreaterThan(pixels[0], pixels[1])
        XCTAssertGreaterThan(pixels[1], pixels[2])
        XCTAssertEqual(pixels[1], 0.5, accuracy: 0.05)
    }
}
