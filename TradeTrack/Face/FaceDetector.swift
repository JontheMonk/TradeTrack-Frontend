import Foundation
import Vision
import CoreVideo
import CoreImage

class FaceDetector {

    func detectFace(in image: CIImage, orientation: CGImagePropertyOrientation = .leftMirrored) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)

        do {
            try handler.perform([request])
        } catch {
            // Optional: log the error, but silently fail
            print("Face detection failed: \(error.localizedDescription)")
            return nil
        }

        return request.results?.first as? VNFaceObservation
    }
}
