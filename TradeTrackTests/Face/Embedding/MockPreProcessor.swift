import CoreML
import CoreVideo

final class MockPreprocessor: PixelPreprocessing {
    var result: MLMultiArray?
    var error: Error?

    func toNCHW(pixelBuffer: CVPixelBuffer) throws -> MLMultiArray {
        if let error { throw error }
        return result!
    }
}
