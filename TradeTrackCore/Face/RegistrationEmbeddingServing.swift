import UIKit
/// Service responsible for producing a **512-dimensional face embedding**
/// from a user-selected image during employee registration.
///
/// This abstraction wraps the full pipeline:
///   1. Convert `UIImage` → upright `CIImage` respecting EXIF orientation
///   2. Detect a face using `FaceAnalyzer` (detector + validator)
///   3. Preprocess + embed using `FaceProcessor` (crop, resize, NCHW, model)
///
/// ViewModels use this instead of talking to Vision or CoreML directly.
/// Errors surface as `AppError` and should be displayed via `ErrorManager`.
public protocol RegistrationEmbeddingServing: Sendable {
    /// Extracts a normalized face embedding from the given image.
    ///
    /// - Parameter image: A user-selected photo (from camera or library).
    /// - Returns: A normalized `FaceEmbedding` (512 floats).
    /// - Throws:
    ///   - `AppError(.faceValidationFailed)` if no valid face is found.
    ///   - `AppError` bubbling up from preprocessing or the ML model.
    func embedding(from image: UIImage) async throws -> FaceEmbedding
}
