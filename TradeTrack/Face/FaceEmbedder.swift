import CoreML
import Foundation

final class FaceEmbedder {
    private let model: FaceEmbeddingModeling
    private let preprocessor: PixelPreprocessing

    init(model: FaceEmbeddingModeling,
         preprocessor: PixelPreprocessing)
    {
        self.model = model
        self.preprocessor = preprocessor
    }

    func embed(from pixelBuffer: CVPixelBuffer) throws -> FaceEmbedding {
        let inputArray: MLMultiArray
        do {
            inputArray = try preprocessor.toNCHW(pixelBuffer: pixelBuffer)
        } catch {
            throw AppError(code: .facePreprocessingFailedRender,
                           underlyingError: error)
        }

        let input = w600k_r50Input(input_1: inputArray)

        let output: w600k_r50Output
        do {
            output = try model.prediction(input: input)
        } catch {
            throw AppError(code: .modelOutputMissing,
                           underlyingError: error)
        }

        guard let multiArray =
            output.featureValue(for: "683")?.multiArrayValue else
        {
            throw AppError(code: .modelOutputMissing)
        }

        let raw = (0..<multiArray.count).map { Float(truncating: multiArray[$0]) }
        return FaceEmbedding(raw)
    }
}
