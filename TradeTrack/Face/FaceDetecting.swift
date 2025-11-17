import Vision
import CoreImage

protocol FaceDetecting {
    func detect(in image: CIImage) -> VNFaceObservation?
}
