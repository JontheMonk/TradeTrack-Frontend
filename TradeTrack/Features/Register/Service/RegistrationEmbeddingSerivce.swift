import UIKit
import Vision
import CoreImage
import TradeTrackCore

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
protocol RegistrationEmbeddingServing {
    /// Extracts a normalized face embedding from the given image.
    ///
    /// - Parameter image: A user-selected photo (from camera or library).
    /// - Returns: A normalized `FaceEmbedding` (512 floats).
    /// - Throws:
    ///   - `AppError(.faceValidationFailed)` if no valid face is found.
    ///   - `AppError` bubbling up from preprocessing or the ML model.
    func embedding(from image: UIImage) throws -> FaceEmbedding
}

/// Concrete implementation of `RegistrationEmbeddingServing`.
///
/// Depends on:
///   • `FaceAnalyzerProtocol` — finds a face and enforces validation rules
///   • `FaceProcessor` — crops → resizes → pixel-preprocesses → embeds
///
/// This keeps the registration flow extremely modular and testable.
final class RegistrationEmbeddingService : RegistrationEmbeddingServing {

    private let extractor: FaceEmbeddingExtracting

    init(extractor: FaceEmbeddingExtracting) {
        self.extractor = extractor
    }

    func embedding(from image: UIImage) throws -> FaceEmbedding {
        guard let ciImage = CIImage(image: image) else {
            throw AppError(code: .imageFailedToLoad)
        }
        
        return try extractor.embedding(from: ciImage)
    }
}

