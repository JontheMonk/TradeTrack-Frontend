import CoreML
import Foundation

class FaceEmbedder {
    private let model: w600k_r50

    init() throws {
        self.model = try w600k_r50(configuration: MLModelConfiguration())
    }

    func embed(from pixelBuffer: CVPixelBuffer) throws -> FaceEmbedding? {
        let inputArray = try toNCHWArray(pixelBuffer)
        let input = w600k_r50Input(input_1: inputArray)
        let output = try model.prediction(input: input)

        guard let multiArray = output.featureValue(for: "683")?.multiArrayValue else {
            return nil
        }

        let raw = (0..<multiArray.count).map { Float(truncating: multiArray[$0]) }
        return FaceEmbedding(values: raw)
    }

    private func toNCHWArray(_ pixelBuffer: CVPixelBuffer) throws -> MLMultiArray {
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
