import Vision
import CoreImage

protocol FaceAnalyzing{
    func analyze(in image: CIImage) -> VNFaceObservation?
}

