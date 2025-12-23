import Vision
import CoreImage

/// A capability that converts a detected face into a normalized 512-dimensional
/// embedding suitable for identity verification.
///
/// Conforming types encapsulate **all preprocessing + embedding logic**, so the
/// caller (usually a ViewModel) doesn't need to know:
///   • how to crop or align the face
///   • how to resize or color-convert the image
///   • how to prepare the ML model input
///   • how to run the embedding model
///   • how to normalize the output
///
/// `FaceProcessing` is deliberately narrow: it assumes the face has already been
/// detected and validated (roll, yaw, bounding box, brightness, etc.).
///
/// ### Typical usage
/// ```swift
/// if let face = analyzer.analyze(in: frame) {
///     let embedding = try processor.process(image: frame, face: face)
/// }
/// ```
///
/// ### Error behavior
/// Implementations may throw if:
///   • the cropped region is invalid
///   • the image cannot be rendered into a pixel buffer
///   • the ML model fails or returns no output
///
/// All thrown errors should be `AppError` so the UI can surface them cleanly.
///
/// - Parameters:
///   - image: The full, upright `CIImage` of the camera frame.
///   - face: A validated `VNFaceObservation` describing the face region.
/// - Returns: A fully normalized `FaceEmbedding`.
public protocol FaceProcessing : Sendable {
    func process(image: CIImage, face: VNFaceObservation) async throws -> FaceEmbedding
}
