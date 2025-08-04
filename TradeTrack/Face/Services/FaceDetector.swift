import Foundation
import Vision
import CoreVideo
import CoreImage

class FaceDetector {
    func detectFace(in image: CIImage, orientation: CGImagePropertyOrientation = .leftMirrored) throws -> VNFaceObservation {
        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)
        return try performRequest(handler)
    }

    private func performRequest(_ handler: VNImageRequestHandler) throws -> VNFaceObservation {
        let request = VNDetectFaceLandmarksRequest()
        
        do {
            try handler.perform([request])
        } catch {
            throw AppError(code: .faceDetectionFailed)
        }

        guard let face = request.results?.first as? VNFaceObservation else {
            throw AppError(code: .noFaceFound)
        }

        return face
    }
}
