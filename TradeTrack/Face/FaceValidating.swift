import Vision
import CoreImage

protocol FaceValidating {
    func isValid(face: VNFaceObservation,
                 in image: CIImage,
                 captureQualityProvider: (VNFaceObservation, CIImage) throws -> Float)
        -> Bool
}
