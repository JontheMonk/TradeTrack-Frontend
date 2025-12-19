import CoreImage
import CoreVideo
import Vision

public protocol FacePreprocessorProtocol: AnyObject {
    func preprocessFace(image: CIImage, face: VNFaceObservation) throws -> CVPixelBuffer
}
