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
/// - The face bounding box is correctly mapped from normalized Vision coordinates.
/// - The face region is cropped and resized using a high-quality Lanczos filter.
/// - Memory is managed via a `CVPixelBufferPool` to prevent per-frame allocations.
/// - Color management is bypassed during intermediate transforms for speed,
///   but the final buffer is rendered in sRGB/BGRA (model expectation).
///
/// ### Pipeline
/// ```text
/// CIImage (upright)
///     └── map bounding box → pixel rect
///         └── crop ROI
///             └── Lanczos resize (scale-to-fill)
///                 └── center crop to exactly 112×112
///                     └── CIContext render → Pooled CVPixelBuffer (sRGB)
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
actor FacePreprocessor: FacePreprocessorProtocol {
    
    private let outputSize: CGSize
    
    // Buffer pool for zero-allocation frames
    private var pixelBufferPool: CVPixelBufferPool?
    private var currentPoolSize: CGSize = .zero

    // Linear working space avoids gamma correction overhead
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
    private static let ctx = CIContext(options: [
        .workingColorSpace: NSNull(), // skip color management during intermediate steps
        .outputColorSpace: sRGB,
        .useSoftwareRenderer: false
    ])

    init(outputSize: CGSize = CGSize(width: 112, height: 112)) {
        self.outputSize = outputSize
    }

    func preprocessFace(image: CIImage, face: VNFaceObservation) async throws -> CVPixelBuffer {
        let extent = image.extent.integral

        let rect = VNImageRectForNormalizedRect(
            face.boundingBox,
            Int(extent.width),
            Int(extent.height)
        ).integral

        let roi = rect.intersection(extent)
        guard !roi.isNull, roi.width > 1, roi.height > 1 else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        let cropped = image.cropped(to: roi)
        let resized = try resize(cropped, to: outputSize)

        // Normalize origin
        let origin = resized.extent.origin
        let normalized = resized.transformed(by: .init(
            translationX: -origin.x,
            y: -origin.y
        ))

        return try renderToPoolBuffer(normalized, size: outputSize)
    }

    private func resize(_ image: CIImage, to size: CGSize) throws -> CIImage {
        guard let lanczos = CIFilter(name: "CILanczosScaleTransform") else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        let scale = max(size.width / image.extent.width, size.height / image.extent.height)

        lanczos.setValue(image, forKey: kCIInputImageKey)
        lanczos.setValue(scale, forKey: kCIInputScaleKey)
        lanczos.setValue(1.0, forKey: kCIInputAspectRatioKey)

        guard var out = lanczos.outputImage else {
            throw AppError(code: .facePreprocessingFailedResize)
        }

        out = out.transformed(by: .init(translationX: -out.extent.origin.x, y: -out.extent.origin.y))

        let crop = CGRect(
            x: (out.extent.width - size.width) * 0.5,
            y: (out.extent.height - size.height) * 0.5,
            width: size.width,
            height: size.height
        )
        return out.cropped(to: crop)
    }


    private func renderToPoolBuffer(_ image: CIImage, size: CGSize) throws -> CVPixelBuffer {
        // Prepare the pool if it doesn't exist or size changed
        if pixelBufferPool == nil || currentPoolSize != size {
            try preparePixelBufferPool(size: size)
        }

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool!, &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw AppError(code: .facePreprocessingFailedRender)
        }

        // Render directly into the recycled buffer
        Self.ctx.render(
            image,
            to: buffer,
            bounds: CGRect(origin: .zero, size: size),
            colorSpace: Self.sRGB
        )

        return buffer
    }

    private func preparePixelBufferPool(size: CGSize) throws {
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey: 3] as CFDictionary
        
        let bufferAttributes: [String: Any] = [
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:], // Critical for GPU/Neural Engine access
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]

        let status = CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            poolAttributes,
            bufferAttributes as CFDictionary,
            &pixelBufferPool
        )

        guard status == kCVReturnSuccess else {
            throw AppError(code: .facePreprocessingFailedRender)
        }
        currentPoolSize = size
    }
}
