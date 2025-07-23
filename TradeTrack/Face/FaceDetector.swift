import Foundation
import Vision
import CoreVideo
import CoreImage

class FaceDetector {
    func detectFace(in image: CIImage, orientation: CGImagePropertyOrientation = .leftMirrored) -> VNFaceObservation? {
        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)
        return performRequest(handler)
    }

    private func performRequest(_ handler: VNImageRequestHandler) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()
        do {
            try handler.perform([request])
            return request.results?.first as? VNFaceObservation
        } catch {
            print("❌ Face detection failed: \(error)")
            return nil
        }
    }
}

