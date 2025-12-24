import CoreML
import Foundation

/// Generates a normalized face embedding from a pixel buffer using the
/// InsightFace (w600k_r50_image) model.
struct FaceEmbedder: FaceEmbeddingProtocol {

    /// CoreML model wrapper that exposes a `prediction` method.
    private let model: FaceEmbeddingModelProtocol

    init(model: FaceEmbeddingModelProtocol) {
        self.model = model
    }

    /// Produces a normalized embedding from a preprocessed pixel buffer.
    ///
    /// - Parameter preprocessed: A Sendable wrapper containing the 112×112 pixel buffer.
    /// - Returns: A L2-normalized `FaceEmbedding`.
    func embed(from preprocessed: CVPixelBuffer) async throws -> FaceEmbedding {

        let input = w600k_r50_imageInput(input_1: preprocessed)

        let output: w600k_r50_imageOutput
        do {
            output = try await model.prediction(input: input)
        } catch {
            throw AppError(
                code: .modelOutputMissing,
                underlyingError: error
            )
        }

        // 3. Extract embedding vector from the "683" output key
        guard let multiArray = output.featureValue(for: "683")?.multiArrayValue else {
            throw AppError(code: .modelOutputMissing)
        }

        let raw = (0..<multiArray.count).map {
            Float(truncating: multiArray[$0])
        }

        return FaceEmbedding(raw)
    }
}
