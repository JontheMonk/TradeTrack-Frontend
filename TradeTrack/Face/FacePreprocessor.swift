import Foundation
import Vision
import CoreImage
import CoreVideo

final class FacePreprocessor {
    private let context: CIContext

    init(context: CIContext = CIContext()) {
        self.context = context
    }

    /// Full preprocessing pipeline: crop → resize → render to pixel buffer
    func preprocessFace(from image: CIImage, face: VNFaceObservation) throws -> CVPixelBuffer {
        let croppedImage = crop(image, using: face)
        let resizedImage = try resize(croppedImage, to: CGSize(width: 112, height: 112))
        return try renderToPixelBuffer(resizedImage, size: CGSize(width: 112, height: 112))
    }

    // MARK: - Crop

    private func crop(_ image: CIImage, using face: VNFaceObservation) -> CIImage {
        let width = image.extent.width
        let height = image.extent.height

        let faceRect = CGRect(
            x: face.boundingBox.origin.x * width,
            y: (1 - face.boundingBox.origin.y - face.boundingBox.height) * height,
            width: face.boundingBox.width * width,
            height: face.boundingBox.height * height
        )

        return image.cropped(to: faceRect)
    }

    // MARK: - Resize

    private func resize(_ image: CIImage, to size: CGSize) throws -> CIImage {
        guard let lanczos = CIFilter(name: "CILanczosScaleTransform") else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        let scale = size.width / image.extent.width
        lanczos.setValue(image, forKey: kCIInputImageKey)
        lanczos.setValue(scale, forKey: kCIInputScaleKey)
        lanczos.setValue(1.0, forKey: kCIInputAspectRatioKey)

        guard let outputImage = lanczos.outputImage else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        return outputImage
    }

    // MARK: - Render to CVPixelBuffer

    private func renderToPixelBuffer(_ image: CIImage, size: CGSize) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?

        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw AppError(code: .facePreprocessingFailedRender)
        }

        context.render(image, to: buffer)
        return buffer
    }
}
