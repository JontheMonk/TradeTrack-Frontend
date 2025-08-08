import Foundation
import Vision
import CoreVideo
import CoreImage
import os.log

class FaceDetector {
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")

    func detectFace(in image: CIImage, orientation: CGImagePropertyOrientation = .leftMirrored) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)

        do {
            try handler.perform([request])
        } catch {
            logger.error("Face detection failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        return request.results?.first as? VNFaceObservation
    }
}
