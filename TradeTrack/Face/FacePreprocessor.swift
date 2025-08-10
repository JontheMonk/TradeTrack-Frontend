import Foundation
import Vision
import CoreImage
import CoreVideo

/// Crops the detected face, resizes to model size, then renders via PixelBufferConverter.
final class FacePreprocessor {
    private let outputSize: CGSize

    init(outputSize: CGSize = CGSize(width: 112, height: 112)) {
        self.outputSize = outputSize
    }

    /// Validate first elsewhere; this just crops/resizes for the model.
    func preprocessFace(from frame: FrameInput, face: VNFaceObservation) throws -> CVPixelBuffer {
        let ciFull  = frame.image
        let rect    = FaceGeometry.pixelRect(for: face, in: frame.buffer)
        let cropped = ciFull.cropped(to: rect)
        let resized = try resize(cropped, to: outputSize)
        return try PixelBufferConverter.from(ciImage: resized)
    }

    // MARK: Resize (Lanczos)
    private func resize(_ image: CIImage, to size: CGSize) throws -> CIImage {
        guard let lanczos = CIFilter(name: "CILanczosScaleTransform") else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        // Scale-to-fill: cover the target in both dimensions
        let sx = size.width  / image.extent.width
        let sy = size.height / image.extent.height
        let scale = max(sx, sy)

        lanczos.setValue(image, forKey: kCIInputImageKey)
        lanczos.setValue(scale, forKey: kCIInputScaleKey)
        lanczos.setValue(1.0,  forKey: kCIInputAspectRatioKey)

        guard var out = lanczos.outputImage else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        // CI may return a non-zero origin; normalize to (0,0)
        let origin = out.extent.origin
        out = out.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))

        // Center-crop to exact target size
        let w = out.extent.width, h = out.extent.height
        let crop = CGRect(x: (w - size.width) * 0.5,
                          y: (h - size.height) * 0.5,
                          width: size.width,
                          height: size.height)
        return out.cropped(to: crop)
    }

}
