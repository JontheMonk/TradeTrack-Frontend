import CoreImage
import CoreVideo
import Vision

/// Crops the detected face from an *already-upright* CIImage, resizes to model size,
/// then renders to a CVPixelBuffer for inference.
final class FacePreprocessor {
    private let outputSize: CGSize

    // Reuse one CIContext with sRGB in/out so P3 photos don't skew inputs.
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
    private static let ctx = CIContext(options: [
        .workingColorSpace: sRGB,
        .outputColorSpace: sRGB
    ])

    init(outputSize: CGSize = CGSize(width: 112, height: 112)) {
        self.outputSize = outputSize
    }

    func preprocessFace(image: CIImage, face: VNFaceObservation) throws -> CVPixelBuffer {
        let extent = image.extent.integral

        // Map normalized bbox -> oriented pixels
        let rect = VNImageRectForNormalizedRect(face.boundingBox,
                                                Int(extent.width),
                                                Int(extent.height)).integral
        let roi = rect.intersection(extent)
        guard !roi.isNull, roi.width > 1, roi.height > 1 else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        // Crop → resize (Lanczos, scale-to-fill + center-crop)
        let cropped = image.cropped(to: roi)
        let resized = try resize(cropped, to: outputSize)

        // Ensure origin is (0,0) before render
        let origin = resized.extent.origin
        let normalized = origin == .zero
            ? resized
            : resized.transformed(by: .init(translationX: -origin.x, y: -origin.y))

        // Render to pixel buffer
        return try renderToPixelBuffer(normalized, size: outputSize)
    }

    // MARK: - Resize (Lanczos, scale-to-fill + center-crop)
    private func resize(_ image: CIImage, to size: CGSize) throws -> CIImage {
        guard let lanczos = CIFilter(name: "CILanczosScaleTransform") else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        let sx = size.width  / image.extent.width
        let sy = size.height / image.extent.height
        let scale = max(sx, sy)

        lanczos.setValue(image, forKey: kCIInputImageKey)
        lanczos.setValue(scale, forKey: kCIInputScaleKey)
        lanczos.setValue(1.0,  forKey: kCIInputAspectRatioKey)

        guard var out = lanczos.outputImage else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        // Rebase to (0,0)
        let o = out.extent.origin
        out = out.transformed(by: .init(translationX: -o.x, y: -o.y))

        // Center-crop to exact target
        let w = out.extent.width, h = out.extent.height
        let crop = CGRect(x: (w - size.width) * 0.5,
                          y: (h - size.height) * 0.5,
                          width: size.width,
                          height: size.height)
        return out.cropped(to: crop)
    }

    // MARK: - CI → CVPixelBuffer render
    private func renderToPixelBuffer(_ image: CIImage, size: CGSize) throws -> CVPixelBuffer {
        let width  = max(1, lround(Double(size.width)))
        let height = max(1, lround(Double(size.height)))

        var pb: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width, height,
                                         kCVPixelFormatType_32BGRA,
                                         attrs as CFDictionary,
                                         &pb)
        guard status == kCVReturnSuccess, let buffer = pb else {
            throw AppError(code: .facePreprocessingFailedRender)
        }

        let h = image.extent.height
        let flip = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: 0, y: -h)

        let corrected = image.transformed(by: flip)
        Self.ctx.render(corrected, to: buffer)

        return buffer
    }
}
