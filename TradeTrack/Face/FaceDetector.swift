import Vision
import CoreImage
import os.log

final class FaceDetector: FaceDetecting {
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")


    /// Detects the first face in the image. No validation.
    func detect(in image: CIImage) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()

        if #available(iOS 17.0, *) {
            request.revision = VNDetectFaceLandmarksRequestRevision3
        }

        let handler = VNImageRequestHandler(ciImage: image, orientation: .up)

        do {
            try handler.perform([request])
            guard let face = request.results?.first else {
                logger.debug("No face detected")
                return nil
            }
            return face
        } catch {
            logger.error("Vision error: \(error.localizedDescription)")
            return nil
        }
    }
}
