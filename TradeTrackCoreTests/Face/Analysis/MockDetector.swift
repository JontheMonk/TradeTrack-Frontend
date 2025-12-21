import Vision
import CoreImage
@testable import TradeTrackCore

class MockDetector: FaceDetectorProtocol {
    let resultFace: VNFaceObservation?
    let resultQuality: Float
    
    init(face: VNFaceObservation?, quality: Float = 1.0) {
        self.resultFace = face
        self.resultQuality = quality
    }
    
    func detect(in image: CIImage) -> (VNFaceObservation, Float)? {
        guard let face = resultFace else { return nil }
        return (face, resultQuality)
    }
}
