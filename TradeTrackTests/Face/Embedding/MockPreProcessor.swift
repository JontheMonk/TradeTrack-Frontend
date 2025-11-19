import CoreML
import CoreVideo

final class MockPreprocessor: PixelPreprocessing {
    var result: MLMultiArray?
    var error: Error?
    
    enum MockPreprocessorError: Error {
        case resultNotSet
    }

    func toNCHW(pixelBuffer: CVPixelBuffer) throws -> MLMultiArray {
        if let error { throw error }
        guard let result else { throw MockPreprocessorError.resultNotSet }
        return result
    }
}
