import CoreML

/// Abstraction for converting a camera frame (`CVPixelBuffer`) into the
/// normalized NCHW tensor format expected by the face-embedding model.
///
/// Why this exists:
/// ----------------
/// - Makes the preprocessor **mockable** in tests (you can inject fake
///   `MLMultiArray` outputs instead of doing real CI/Metal work).
/// - Decouples `FaceEmbedder` from the pixel-buffer → tensor logic.
/// - Allows you to swap preprocessing strategies without touching the model.
///
/// Expected output:
/// ----------------
/// - A 4-D `MLMultiArray` shaped like `[1, 3, H, W]`
/// - Channels must be **RGB** or **BGR** depending on the model requirements.
/// - Pixel values should already be **normalized** (e.g., 0–1 or standardized),
///   depending on how the CoreML model was converted.
///
/// Errors:
/// -------
/// Implementors should throw meaningful errors when:
///   - the pixel buffer lacks a base address
///   - the buffer cannot be converted into CIImage/CGImage
///   - resizing or color-space conversion fails
///
/// `FaceEmbedder` will map thrown errors to `AppError(code: .facePreprocessingFailedRender)`.
protocol PixelPreprocessorProtocol : Sendable {
    /// Converts a pixel buffer into a normalized NCHW (1×3×H×W) tensor.
    ///
    /// - Parameter pixelBuffer: Raw camera image in BGRA/YUV/etc.
    /// - Returns: A model-ready `MLMultiArray`.
    /// - Throws: If pixel conversion, resize, or normalization fails.
    func toNCHW(pixelBuffer: CVPixelBuffer) throws -> MLMultiArray
}
