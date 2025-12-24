import CoreImage
import CoreVideo
import Vision

protocol FacePreprocessorProtocol: Sendable {
    func preprocessFace(image: CIImage, face: VNFaceObservation) async throws -> SendablePixelBuffer
}
