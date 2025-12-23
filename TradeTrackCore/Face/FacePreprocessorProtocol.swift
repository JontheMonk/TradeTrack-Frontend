import CoreImage
import CoreVideo
import Vision

public protocol FacePreprocessorProtocol: Sendable {
    func preprocessFace(image: CIImage, face: VNFaceObservation) async throws -> CVPixelBuffer
}
