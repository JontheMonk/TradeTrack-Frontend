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
        let ciUpright = try Self.makeUprightCIImage(from: image)
        return try extractor.embedding(from: ciUpright)
    }
}

// MARK: - Private helpers

private extension RegistrationEmbeddingService {
    /// Produces an upright CIImage that reflects the UIImage’s EXIF orientation.
    ///
    /// Vision requires image orientation to be explicitly expressed.
    /// This helper normalizes all the different `UIImage` storage cases:
    ///  • backed by CGImage
    ///  • backed by CIImage
    ///  • or created dynamically
    ///
    /// Throws `AppError(.imageFailedToLoad)` if conversion is impossible.
    static func makeUprightCIImage(from image: UIImage) throws -> CIImage {
        if let cg = image.cgImage {
            let exif = CGImagePropertyOrientation(ui: image.imageOrientation)
            return CIImage(cgImage: cg).oriented(exif)
        }
        if let ci = image.ciImage {
            let exif = CGImagePropertyOrientation(ui: image.imageOrientation)
            return ci.oriented(exif)
        }
        if let ci = CIImage(
            image: image,
            options: [.applyOrientationProperty: false]
        ) {
            let exif = CGImagePropertyOrientation(ui: image.imageOrientation)
            return ci.oriented(exif)
        }
        throw AppError(code: .imageFailedToLoad)
    }
}

// MARK: - UIImage → EXIF orientation bridge

private extension CGImagePropertyOrientation {
    /// Converts UIKit's `UIImage.Orientation` into the EXIF orientation values
    /// that Vision expects. This mapping is required for correct face detection.
    init(ui: UIImage.Orientation) {
        switch ui {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
