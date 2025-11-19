import CoreImage
import Vision

// MARK: - Image Generators

/// Creates a solid-color `CIImage` of the given pixel size.
///
/// Used for tests where the content does not matter,
/// only that the image is non-empty and deterministic.
///
/// - Parameters:
///   - width:  Image width in pixels.
///   - height: Image height in pixels.
///   - color:  Fill color for the image.
/// - Returns: A `CIImage` of size (width × height).
func makeImage(width: Int, height: Int, color: CIColor = .red) -> CIImage {
    let filter = CIFilter(
        name: "CIConstantColorGenerator",
        parameters: [kCIInputColorKey: color]
    )!
    
    // CIConstantColorGenerator produces an infinite image,
    // so we crop it down to the requested rectangle.
    return filter.outputImage!
        .cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
}

/// Creates a left→right grayscale gradient image.
///
/// This is used to verify geometric correctness in preprocessing:
/// correct center-crop, scale-to-fill behavior, and horizontal alignment.
///
/// - Dark (0.0) at the left edge
/// - Light (1.0) at the right edge
///
/// Pixel values make misalignment easy to detect in tests.
///
/// - Parameters:
///   - width:  Image width in pixels.
///   - height: Image height in pixels.
/// - Returns: A horizontal gradient `CIImage`.
func makeHorizontalGradientImage(width: Int, height: Int) -> CIImage {
    let filter = CIFilter(name: "CILinearGradient")!
    filter.setDefaults()

    filter.setValue(
        CIVector(x: 0, y: CGFloat(height) / 2),
        forKey: "inputPoint0"
    )
    filter.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: "inputColor0")

    filter.setValue(
        CIVector(x: CGFloat(width), y: CGFloat(height) / 2),
        forKey: "inputPoint1"
    )
    filter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1")

    // CILinearGradient generates an infinite gradient;
    // we crop to the desired size.
    return filter.outputImage!
        .cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
}

/// Creates a top→bottom grayscale gradient image.
///
/// Used to test vertical alignment in the preprocessing pipeline:
/// scale direction, vertical centering, and crop correctness.
///
/// - Dark (0.0) at the top
/// - Light (1.0) at the bottom
///
/// - Parameters:
///   - width:  Image width in pixels.
///   - height: Image height in pixels.
/// - Returns: A vertical gradient `CIImage`.
func makeVerticalGradientImage(width: Int, height: Int) -> CIImage {
    let filter = CIFilter(name: "CILinearGradient")!
    filter.setDefaults()

    filter.setValue(
        CIVector(x: CGFloat(width) / 2, y: 0),
        forKey: "inputPoint0"
    )
    filter.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: "inputColor0")

    filter.setValue(
        CIVector(x: CGFloat(width) / 2, y: CGFloat(height)),
        forKey: "inputPoint1"
    )
    filter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1")

    return filter.outputImage!
        .cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
}


// MARK: - Pixel Sampling Utilities

/// Extracts pixel values from specific column positions in a `CVPixelBuffer`.
///
/// This samples the **middle row** (y = height / 2) at each requested X-coordinate,
/// reading the **red channel** as a normalized float [0, 1].
///
/// Useful for correctness tests involving:
/// - horizontal alignment
/// - center cropping
/// - scale-to-fill behavior
/// - flipped or shifted ROIs
///
/// - Parameters:
///   - pb: The pixel buffer produced by `FacePreprocessor`.
///   - columns: X-coordinates to sample (will be clamped).
/// - Returns: An array of normalized red-channel values.
func pixelColumns(from pb: CVPixelBuffer, columns: [Int]) -> [Float] {
    CVPixelBufferLockBaseAddress(pb, [])
    defer { CVPixelBufferUnlockBaseAddress(pb, []) }

    let w = CVPixelBufferGetWidth(pb)
    let h = CVPixelBufferGetHeight(pb)
    let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
    let stride = CVPixelBufferGetBytesPerRow(pb)

    var values: [Float] = []

    for col in columns {
        let x = min(max(col, 0), w - 1)
        let offset = x * 4 + (h / 2) * stride
        let r = Float(base[offset + 2]) / 255 // red channel
        values.append(r)
    }

    return values
}

/// Extracts pixel values from specific row positions in a `CVPixelBuffer`.
///
/// This samples the **middle column** (x = width / 2) at each requested Y-coordinate,
/// reading the **red channel** as a normalized float [0, 1].
///
/// Useful for correctness tests involving:
/// - vertical alignment
/// - center cropping
/// - top/bottom drift
/// - incorrect ROI expansion or scaling
///
/// - Parameters:
///   - pb: The pixel buffer produced by `FacePreprocessor`.
///   - rows: Y-coordinates to sample (will be clamped).
/// - Returns: An array of normalized red-channel values.
func pixelRows(from pb: CVPixelBuffer, rows: [Int]) -> [Float] {
    CVPixelBufferLockBaseAddress(pb, [])
    defer { CVPixelBufferUnlockBaseAddress(pb, []) }

    let w = CVPixelBufferGetWidth(pb)
    let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
    let stride = CVPixelBufferGetBytesPerRow(pb)

    var values: [Float] = []

    for row in rows {
        let y = min(max(row, 0), CVPixelBufferGetHeight(pb) - 1)
        let offset = (w / 2) * 4 + y * stride
        let r = Float(base[offset + 2]) / 255 // red channel
        values.append(r)
    }

    return values
}
