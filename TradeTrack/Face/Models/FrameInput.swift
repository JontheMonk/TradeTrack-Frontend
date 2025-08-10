import UIKit
import CoreImage
import Vision

struct FrameInput {
    let buffer: CVPixelBuffer
    let orientation: CGImagePropertyOrientation
    var image: CIImage { CIImage(cvPixelBuffer: buffer) }
}

extension CGImagePropertyOrientation {
    init(ui: UIImage.Orientation) {
        switch ui {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

enum PhotoFrameBuilder {
    static func makeFrame(from uiImage: UIImage) throws -> FrameInput {
        // Normalize to CIImage early
        let ci = uiImage.cgImage.map(CIImage.init(cgImage:)) ?? (CIImage(image: uiImage) ?? CIImage())
        let buf = try PixelBufferConverter.from(ciImage: ci) // Core converter (CIImage-only)
        let orient = CGImagePropertyOrientation(ui: uiImage.imageOrientation)
        return FrameInput(buffer: buf, orientation: orient)
    }
}
