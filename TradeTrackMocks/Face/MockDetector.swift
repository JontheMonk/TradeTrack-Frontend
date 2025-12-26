@preconcurrency import Vision
import CoreImage
@testable import TradeTrackCore

struct MockDetector: FaceDetectorProtocol {
    let resultFace: VNFaceObservation?
    let resultQuality: Float

    // Must be async to satisfy the protocol
    func detect(in image: CIImage) async -> (VNFaceObservation, Float)? {
        guard let face = resultFace else { return nil }
        return (face, resultQuality)
    }

    func reset() async {
        // No-op
    }
}
