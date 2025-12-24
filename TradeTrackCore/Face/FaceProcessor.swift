//
//  FaceProcessor.swift
//
//  Orchestrates the final two stages of the face-recognition pipeline:
//  1. Preprocessing the cropped face region into a model-ready pixel buffer.
//  2. Running the embedding model to produce a normalized FaceEmbedding.
//
//  This class contains no Vision logic and no validation logic — it assumes
//  the caller (FaceAnalyzer) has already provided a single, high-quality
//  `VNFaceObservation`. Its job is to transform that into the 512-dimensional
//  embedding used for identity verification.
//

import Vision
import CoreImage

/// A high-level component that converts a detected face into a normalized
/// 512-dimensional embedding by delegating to:
///
/// - `FacePreprocessor` — crops the face, resizes to 112×112, and renders to
///   a BGRA `CVPixelBuffer`.
/// - `FaceEmbedder` — runs the InsightFace model and normalizes the output.
///
/// This keeps your camera/verification logic simple and allows the entire
/// preprocessing + embedding pipeline to be tested independently.
///
/// ### Typical usage
/// ```swift
/// if let face = analyzer.analyze(in: frame) {
///     let embedding = try processor.process(image: frame, face: face)
/// }
/// ```
///
/// ### Error Handling
/// Any preprocessing or model failures bubble up as typed `AppError` values:
/// - `.facePreprocessingFailed*`
/// - `.modelOutputMissing`
///
/// This ensures the UI can display clear failure states (“Try again,” etc.)
struct FaceProcessor : FaceProcessing {

    /// Handles cropping and resizing of the face region.
    private let preprocessor: FacePreprocessor

    /// Handles embedding model inference and normalization.
    private let embedder: FaceEmbedder

    init(
        preprocessor: FacePreprocessor,
        embedder: FaceEmbedder
    ) {
        self.preprocessor = preprocessor
        self.embedder = embedder
    }

    /// Produces a normalized embedding from the given image + detected face.
    ///
    /// - Parameters:
    ///   - image: Upright `CIImage` representing the full camera frame.
    ///   - face: A validated face observation from `FaceAnalyzer`.
    ///
    /// - Returns: A fully normalized `FaceEmbedding`.
    /// - Throws: Forwarded `AppError` from preprocessing or embedding.
    func process(image: CIImage, face: VNFaceObservation) async throws -> FaceEmbedding {
        let preprocessed = try await preprocessor.preprocessFace(image: image, face: face)
        return try await embedder.embed(from: preprocessed.buffer)
    }
}
