import Foundation
import Vision
import CoreImage
import os.log

final class FaceDetector {
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")

    func detectFace(in image: CIImage) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()
        if #available(iOS 17.0, *) {
            request.revision = VNDetectFaceLandmarksRequestRevision3
        }
        let handler = VNImageRequestHandler(ciImage: image, orientation: .up, options: [:])

        do {
            try handler.perform([request])
        } catch {
            logger.error("Face detection failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        return (request.results)?.first
    }
}
