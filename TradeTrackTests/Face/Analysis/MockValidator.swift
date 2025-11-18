import Vision
import CoreImage

final class MockValidator: FaceValidating {
    var result: Bool

    init(result: Bool) {
        self.result = result
    }

    func isValid(
        face: VNFaceObservation,
        in image: CIImage,
        captureQualityProvider: (VNFaceObservation, CIImage) throws -> Float
    ) -> Bool {
        return result
    }
}
