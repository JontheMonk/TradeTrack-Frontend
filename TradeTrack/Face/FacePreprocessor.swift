import SwiftUI
import Vision

class FacePreprocessor{
    func preprocessFace(from image: CIImage, face: VNFaceObservation) -> CVPixelBuffer? {
        let cropped = crop(image, using: face)
        guard let resized = resize(cropped, to: CGSize(width: 112, height: 112)) else {
            return nil
        }
        return renderToPixelBuffer(resized, size: CGSize(width: 112, height: 112))
    }
    
    private func crop(_ ciImage: CIImage, using face: VNFaceObservation) -> CIImage {
        let width = ciImage.extent.width
        let height = ciImage.extent.height

        let faceRect = CGRect(
            x: face.boundingBox.origin.x * width,
            y: (1 - face.boundingBox.origin.y - face.boundingBox.height) * height,
            width: face.boundingBox.width * width,
            height: face.boundingBox.height * height
        )

        return ciImage.cropped(to: faceRect)
    }

    private func resize(_ image: CIImage, to size: CGSize) -> CIImage? {
        let scale = size.width / image.extent.width
        let lanczos = CIFilter(name: "CILanczosScaleTransform")!
        lanczos.setValue(image, forKey: kCIInputImageKey)
        lanczos.setValue(scale, forKey: kCIInputScaleKey)
        lanczos.setValue(1.0, forKey: kCIInputAspectRatioKey)
        return lanczos.outputImage
    }
    
    private func renderToPixelBuffer(_ image: CIImage, size: CGSize) -> CVPixelBuffer? {
        let context = CIContext()
        var buffer: CVPixelBuffer?

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width), Int(size.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &buffer
        )

        guard status == kCVReturnSuccess, let finalBuffer = buffer else {
            return nil
        }

        context.render(image, to: finalBuffer)
        return finalBuffer
    }
}
