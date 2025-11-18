import CoreML
import CoreVideo

struct RealPixelPreprocessor: PixelPreprocessing {

    func toNCHW(pixelBuffer: CVPixelBuffer) throws -> MLMultiArray {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw AppError(code: .pixelBufferMissingBaseAddress)
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // Base address = raw BGRA pixel memory
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        // Create CoreML array: shape [3, H, W]
        let array: MLMultiArray
        do {
            array = try MLMultiArray(shape: [3, height as NSNumber, width as NSNumber],
                                     dataType: .float32)
        } catch {
            throw AppError(code: .facePreprocessingFailedResize, underlyingError: error)
        }

        let ptr = UnsafeMutablePointer<Float32>(OpaquePointer(array.dataPointer))

        // Fill NCHW buffer
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4

                // Extract BGRA pixel
                let b = Float32(buffer[i + 0])
                let g = Float32(buffer[i + 1])
                let r = Float32(buffer[i + 2])

                // Normalize like InsightFace expects
                let rn = (r - 127.5) / 128.0
                let gn = (g - 127.5) / 128.0
                let bn = (b - 127.5) / 128.0

                let idx = y * width + x

                // N C H W indexing
                ptr[0 * width * height + idx] = rn
                ptr[1 * width * height + idx] = gn
                ptr[2 * width * height + idx] = bn
            }
        }

        return array
    }
}
