import CoreML
import Foundation


class FaceEmbedder {
    private let model: w600k_r50

    init() throws {
        self.model = try w600k_r50(configuration: MLModelConfiguration())
    }

    func embed(from pixelBuffer: CVPixelBuffer) throws -> [Float]? {
        let inputArray = try PixelBufferConverter.toNCHWArray(pixelBuffer)
        let input = w600k_r50Input(input_1: inputArray)
        let output = try model.prediction(input: input)

        guard let multiArray = output.featureValue(for: "683")?.multiArrayValue else {
            return nil
        }

        let raw = (0..<multiArray.count).map { Float(truncating: multiArray[$0]) }
        let norm = sqrt(raw.reduce(0) { $0 + $1 * $1 })
        return norm > 0 ? raw.map { $0 / norm } : nil
    }
}
