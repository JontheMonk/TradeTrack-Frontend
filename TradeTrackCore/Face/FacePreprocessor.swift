//
//  FacePreprocessor.swift
//
//  Extracts, normalizes, and resizes a detected face region into a
//  CoreML-ready pixel buffer (112×112, BGRA). This is the final image
//  transformation step before embedding.
//
//  Responsibilities:
//  - Map Vision’s normalized bounding box into pixel coordinates.
//  - Crop the face region from an upright CIImage.
//  - Perform high-quality Lanczos scaling with center-crop semantics.
//  - Convert the CIImage into a model-compatible CVPixelBuffer.
//  - Enforce exact 112×112 output for InsightFace (w600k_r50).
//
//  Errors are wrapped in `AppError` with specific preprocessing codes.
//  This ensures the calling pipeline can gracefully handle invalid faces,
//  corrupt buffers, or Vision inconsistencies.
//

import CoreImage
import CoreVideo
import Vision

/// Performs all preprocessing required to convert a detected face (`VNFaceObservation`)
/// into a 112×112 pixel buffer suitable for the InsightFace embedding model.
///
/// This step ensures that:
/// - the face bounding box is correctly mapped from normalized Vision coordinates,
/// - the face region is cropped and resized using a high-quality, deterministic process,
/// - the image is rendered in sRGB and BGRA format (model expectation),
/// - the pixel buffer is safe to pass directly to the `PixelPreprocessorProtocol`
///   or embedding model.
///
/// ### Pipeline
/// ```text
/// CIImage (upright)
///     └── map bounding box → pixel rect
///         └── crop ROI
///             └── Lanczos resize (scale-to-fill)
///                 └── center crop to exactly 112×112
///                     └── CIContext render → CVPixelBuffer
/// ```
///
/// ### Failure cases
/// Throws specific `AppError` codes when:
/// - bounding box is invalid or outside image bounds
/// - resizing/filter creation fails
/// - pixel buffer allocation fails
/// - rendering fails
///
/// These errors allow the upstream `FaceAnalyzer` or `FaceProcessor` to
/// reject the frame cleanly.
final class FacePreprocessor : FacePreprocessorProtocol {

    /// Target output size, typically 112×112 for InsightFace.
    private let outputSize: CGSize

    // Reuse a single CIContext for performance and consistent sRGB output.
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
    private static let ctx = CIContext(options: [
        .workingColorSpace: sRGB,
        .outputColorSpace: sRGB
    ])

    init(outputSize: CGSize = CGSize(width: 112, height: 112)) {
        self.outputSize = outputSize
    }

    /// Crops, resizes, and renders the face region to a CVPixelBuffer.
    ///
    /// - Parameters:
    ///   - image: Upright `CIImage` frame.
    ///   - face: The detected face observation whose bounding box is used.
    ///
    /// - Throws:
    ///   - `.facePreprocessingFailedResize` if bounding box or scaling fails.
    ///   - `.facePreprocessingFailedRender` if pixel buffer allocation or
    ///     CIContext rendering fails.
    ///
    /// - Returns: A BGRA `CVPixelBuffer` of size `outputSize`.
    func preprocessFace(image: CIImage, face: VNFaceObservation) throws -> CVPixelBuffer {
        let extent = image.extent.integral

        // Convert Vision's normalized bounding box → pixel coordinates.
        let rect = VNImageRectForNormalizedRect(
            face.boundingBox,
            Int(extent.width),
            Int(extent.height)
        ).integral

        let roi = rect.intersection(extent)
        guard !roi.isNull, roi.width > 1, roi.height > 1 else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        // High-quality crop and Lanczos resize.
        let cropped = image.cropped(to: roi)
        let resized = try resize(cropped, to: outputSize)

        // Re-normalize origin before rendering.
        let origin = resized.extent.origin
        let normalized = origin == .zero
            ? resized
            : resized.transformed(by: .init(
                translationX: -origin.x,
                y: -origin.y
            ))

        // Render CIImage → CVPixelBuffer.
        return try renderToPixelBuffer(normalized, size: outputSize)
    }

    // MARK: - Resize (Lanczos, scale-to-fill + center-crop)

    /// Resizes the image using `CILanczosScaleTransform` and center-crop.
    private func resize(_ image: CIImage, to size: CGSize) throws -> CIImage {
        guard let lanczos = CIFilter(name: "CILanczosScaleTransform") else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        let sx = size.width  / image.extent.width
        let sy = size.height / image.extent.height
        let scale = max(sx, sy) // scale-to-fill

        lanczos.setValue(image, forKey: kCIInputImageKey)
        lanczos.setValue(scale, forKey: kCIInputScaleKey)
        lanczos.setValue(1.0,  forKey: kCIInputAspectRatioKey)

        guard var out = lanczos.outputImage else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        // Reset origin to simplify cropping.
        let o = out.extent.origin
        out = out.transformed(by: .init(translationX: -o.x, y: -o.y))

        // Center crop to the final target resolution.
        let w = out.extent.width
        let h = out.extent.height
        let crop = CGRect(
            x: (w - size.width) * 0.5,
            y: (h - size.height) * 0.5,
            width: size.width,
            height: size.height
        )
        return out.cropped(to: crop)
    }

    // MARK: - CI → CVPixelBuffer Render

    /// Renders the normalized CIImage into a BGRA pixel buffer.
    private func renderToPixelBuffer(_ image: CIImage, size: CGSize) throws -> CVPixelBuffer {
        let width  = max(1, lround(Double(size.width)))
        let height = max(1, lround(Double(size.height)))

        var pb: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pb
        )

        guard status == kCVReturnSuccess, let buffer = pb else {
            throw AppError(code: .facePreprocessingFailedRender)
        }

        // CIImage coordinates are Y-flipped relative to CVPixelBuffer.
        let h = image.extent.height
        let flip = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: 0, y: -h)

        let corrected = image.transformed(by: flip)
        Self.ctx.render(corrected, to: buffer)

        return buffer
    }
}
