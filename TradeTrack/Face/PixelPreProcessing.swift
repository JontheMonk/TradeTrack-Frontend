import CoreML

protocol PixelPreprocessing {
    func toNCHW(pixelBuffer: CVPixelBuffer) throws -> MLMultiArray
}
