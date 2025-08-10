import CoreImage
import CoreVideo
import UIKit

enum PixelBufferConverter {
    private static let ctx = CIContext(options: nil)

    static func from(ciImage: CIImage, size: CGSize? = nil) throws -> CVPixelBuffer {
        let targetSize = size ?? ciImage.extent.size
        var pb: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(targetSize.width),
            Int(targetSize.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pb
        )
        guard status == kCVReturnSuccess, let buffer = pb else {
            throw AppError(code: .facePreprocessingFailedRender)
        }

        // If a size was provided, scale; else render as-is
        let imageToRender: CIImage
        if let size = size {
            let sx = size.width / ciImage.extent.width
            let sy = size.height / ciImage.extent.height
            imageToRender = ciImage.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
        } else {
            imageToRender = ciImage
        }

        ctx.render(imageToRender, to: buffer)
        return buffer
    }

    static func from(uiImage: UIImage) throws -> CVPixelBuffer {
        guard let cg = uiImage.cgImage else {
            // Fallback via CIImage if needed
            let ci = CIImage(image: uiImage) ?? CIImage()
            return try from(ciImage: ci)
        }
        return try from(ciImage: CIImage(cgImage: cg))
    }
}
