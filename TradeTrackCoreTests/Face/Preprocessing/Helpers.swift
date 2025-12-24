import XCTest
import Vision
import CoreImage

// MARK: - Image Generators

func makeImage(width: Int, height: Int, color: CIColor = .red) -> CIImage {
    return CIImage(color: color).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
}

func makeHorizontalGradientImage(width: Int, height: Int) -> CIImage {
    let filter = CIFilter(name: "CILinearGradient")!
    filter.setDefaults()
    filter.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint0")
    filter.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: "inputColor0")
    filter.setValue(CIVector(x: CGFloat(width), y: 0), forKey: "inputPoint1")
    filter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1")
    return filter.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
}

func makeVerticalGradientImage(width: Int, height: Int) -> CIImage {
    let filter = CIFilter(name: "CILinearGradient")!
    filter.setDefaults()
    filter.setValue(CIVector(x: 0, y: CGFloat(height)), forKey: "inputPoint0") // Top (Dark)
    filter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor0")
    filter.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint1")               // Bottom (Light)
    filter.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: "inputColor1")
    return filter.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
}

// MARK: - Pixel Sampling Utilities

func pixelColumns(from pb: CVPixelBuffer, columns: [Int]) -> [Float] {
    CVPixelBufferLockBaseAddress(pb, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }

    let w = CVPixelBufferGetWidth(pb)
    let h = CVPixelBufferGetHeight(pb)
    let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
    let stride = CVPixelBufferGetBytesPerRow(pb)

    return columns.map { col in
        let x = min(max(col, 0), w - 1)
        let offset = x * 4 + (h / 2) * stride
        return Float(base[offset + 2]) / 255.0 // Red channel
    }
}

func pixelRows(from pb: CVPixelBuffer, rows: [Int]) -> [Float] {
    CVPixelBufferLockBaseAddress(pb, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pb, .readOnly) }

    let w = CVPixelBufferGetWidth(pb)
    let h = CVPixelBufferGetHeight(pb)
    let base = CVPixelBufferGetBaseAddress(pb)!.assumingMemoryBound(to: UInt8.self)
    let stride = CVPixelBufferGetBytesPerRow(pb)

    return rows.map { row in
        let y = min(max(row, 0), h - 1)
        let offset = (w / 2) * 4 + y * stride
        return Float(base[offset + 2]) / 255.0 // Red channel
    }
}
