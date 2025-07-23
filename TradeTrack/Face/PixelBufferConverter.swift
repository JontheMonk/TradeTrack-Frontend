import CoreML
import CoreVideo
import CoreImage

class PixelBufferConverter {
    static func renderToPixelBuffer(_ image: CIImage, size: CGSize) -> CVPixelBuffer? {
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

    static func toNCHWArray(_ pixelBuffer: CVPixelBuffer) throws -> MLMultiArray {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw NSError(domain: "PixelBuffer", code: 1, userInfo: [NSLocalizedDescriptionKey: "No base address"])
        }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let array = try MLMultiArray(shape: [3, 112, 112], dataType: .float32)
        let ptr = UnsafeMutablePointer<Float32>(OpaquePointer(array.dataPointer))

        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let r = (Float32(buffer[i + 2]) - 127.5) / 128.0
                let g = (Float32(buffer[i + 1]) - 127.5) / 128.0
                let b = (Float32(buffer[i + 0]) - 127.5) / 128.0

                let index = y * width + x
                ptr[0 * height * width + index] = r
                ptr[1 * height * width + index] = g
                ptr[2 * height * width + index] = b
            }
        }

        return array
    }
}
