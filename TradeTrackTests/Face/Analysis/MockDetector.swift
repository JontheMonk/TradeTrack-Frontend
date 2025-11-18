import Vision
import CoreImage

final class MockDetector: FaceDetecting {
    var result: VNFaceObservation?

    init(result: VNFaceObservation?) {
        self.result = result
    }

    func detect(in image: CIImage) -> VNFaceObservation? {
        return result
    }
}
