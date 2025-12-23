//
//  FaceEmbedder.swift
//
//  Converts a preprocessed pixel buffer into a normalized face embedding
//  using the InsightFace (w600k_r50) CoreML model. This is the final stage
//  before backend verification.
//
//  Responsibilities:
//  1. Convert image into NCHW tensor via `PixelPreprocessorProtocol`
//  2. Run the CoreML model
//  3. Extract the embedding vector (“683” output key)
//  4. Normalize the embedding using `FaceEmbedding`
//

import CoreML
import Foundation

/// Generates a normalized face embedding from a pixel buffer using the
/// InsightFace (w600k_r50) model.
///
/// The embedder is intentionally small and strict:
/// - It expects a **single face** extracted & preprocessed in advance.
/// - It uses `PixelPreprocessorProtocol` to convert the pixel buffer into
///   `[1 × 3 × 112 × 112]` NCHW format.
/// - It calls `FaceEmbeddingModelProtocol.prediction` to run inference.
/// - It extracts the vector from the model’s "683" output feature.
/// - It wraps the result in `FaceEmbedding`, which applies L2 normalization.
///
/// ### Error Handling
/// All errors are wrapped into `AppError` with specific codes:
/// - `.facePreprocessingFailedRender` if the pixel buffer → MLMultiArray
///   conversion fails.
/// - `.modelOutputMissing` if the ML model throws OR the "683" feature
///   is missing or malformed.
///
/// This ensures upstream callers (FaceProcessor, Verification flow) receive
/// consistent, user-friendly error states.
///
/// ### Typical Usage
/// ```swift
/// let pb = try preprocessor.preprocessFace(image: img, face: face)  // 112×112
/// let embedding = try embedder.embed(from: pb)
/// let vector = embedding.values  // normalized [Float]
/// ```
struct FaceEmbedder : FaceEmbeddingProtocol {

    /// CoreML model wrapper that exposes a `prediction` method.
    private let model: FaceEmbeddingModelProtocol

    /// Converts CVPixelBuffer → normalized NCHW MLMultiArray.
    private let preprocessor: PixelPreprocessorProtocol

    init(
        model: FaceEmbeddingModelProtocol,
        preprocessor: PixelPreprocessorProtocol
    ) {
        self.model = model
        self.preprocessor = preprocessor
    }

    /// Produces a normalized embedding from a preprocessed pixel buffer.
    ///
    /// - Parameter pixelBuffer: A 112×112 RGB buffer containing a face ROI.
    /// - Returns: A L2-normalized `FaceEmbedding`.
    /// - Throws: `AppError` on preprocessing or model inference failure.
    func embed(from pixelBuffer: CVPixelBuffer) async throws -> FaceEmbedding {

        // Convert pixel buffer → NCHW
        let inputArray: MLMultiArray
        do {
            inputArray = try preprocessor.toNCHW(pixelBuffer: pixelBuffer)
        } catch {
            throw AppError(
                code: .facePreprocessingFailedRender,
                underlyingError: error
            )
        }

        // Construct CoreML input
        let input = w600k_r50Input(input_1: inputArray)

        // Run the model
        let output: w600k_r50Output
        do {
            output = try await model.prediction(input: input)
        } catch {
            throw AppError(
                code: .modelOutputMissing,
                underlyingError: error
            )
        }

        // Extract embedding vector
        guard let multiArray =
            output.featureValue(for: "683")?.multiArrayValue
        else {
            throw AppError(code: .modelOutputMissing)
        }

        // Convert MLMultiArray → [Float]
        let raw = (0..<multiArray.count).map {
            Float(truncating: multiArray[$0])
        }

        // Normalize & wrap
        return FaceEmbedding(raw)
    }
}
