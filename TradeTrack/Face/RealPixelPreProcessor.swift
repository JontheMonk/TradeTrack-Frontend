import CoreML
import CoreVideo

/// Concrete pixel-preprocessor that converts a BGRA `CVPixelBuffer` into a
/// normalized NCHW tensor suitable for InsightFace / w600k_r50.
///
/// Pipeline:
/// --------
/// 1. Locks the pixel buffer and reads raw BGRA bytes.
/// 2. Converts each pixel to **R, G, B** floats.
/// 3. Applies InsightFace normalization: `(value - 127.5) / 128`.
/// 4. Writes data into an `MLMultiArray` shaped **[3, H, W]** in NCHW order.
///
/// Why this exists:
/// ----------------
/// - CoreML models trained with InsightFace expect *exact* preprocessing.
/// - This isolates the low-level pixel handling so `FaceEmbedder` stays clean.
/// - Mockable in tests (using `MockPreprocessor`) so you never manually build
///   fake pixel buffers during unit tests.
///
/// Error behavior:
/// ---------------
/// - Throws `.pixelBufferMissingBaseAddress` if buffer memory cannot be read.
/// - Throws `.facePreprocessingFailedResize` if the `MLMultiArray` allocation
///   fails (rare, but safe to surface).
///
/// Notes:
/// ------
/// - Assumes the pixel buffer is already *upright* and *112×112* (or whatever
///   size the model expects); resizing happens earlier in `FacePreprocessor`.
/// - Writes directly into the underlying `MLMultiArray` memory for speed.
///
/// Output:
/// -------
/// A fully normalized RGB tensor ready to be fed into `w600k_r50Input`.
struct RealPixelPreprocessor: PixelPreprocessorProtocol {

    func toNCHW(pixelBuffer: CVPixelBuffer) throws -> MLMultiArray {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw AppError(code: .pixelBufferMissingBaseAddress)
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        let array: MLMultiArray
        do {
            array = try MLMultiArray(
                shape: [3, height as NSNumber, width as NSNumber],
                dataType: .float32
            )
        } catch {
            throw AppError(
                code: .facePreprocessingFailedResize,
                underlyingError: error
            )
        }

        let ptr = UnsafeMutablePointer<Float32>(OpaquePointer(array.dataPointer))

        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4

                let b = Float32(buffer[i + 0])
                let g = Float32(buffer[i + 1])
                let r = Float32(buffer[i + 2])

                // InsightFace normalization
                let rn = (r - 127.5) / 128.0
                let gn = (g - 127.5) / 128.0
                let bn = (b - 127.5) / 128.0

                let idx = y * width + x

                ptr[0 * width * height + idx] = rn
                ptr[1 * width * height + idx] = gn
                ptr[2 * width * height + idx] = bn
            }
        }

        return array
    }
}
