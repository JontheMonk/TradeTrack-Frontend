import Foundation
import Vision
import CoreImage
import os.log

final class FaceDetector {
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")
    
    // Validation tunables
    private let maxRollDeg: Float = 15
    private let maxYawDeg: Float = 15
    private let minQuality: Float = 0.25
    private let minFaceLength: CGFloat = 0.20 // min(r.width, r.height) in normalized coords

    func detectAndValidate(in image: CIImage) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()
        if #available(iOS 17.0, *) {
            request.revision = VNDetectFaceLandmarksRequestRevision3
        }
        let handler = VNImageRequestHandler(ciImage: image, orientation: .up, options: [:])

        do {
            try handler.perform([request])
            guard let face = request.results?.first else {
                logger.debug("No face detected")
                return nil
            }

            // Validate face
            guard let roll = face.roll?.floatValue, let yaw = face.yaw?.floatValue else {
                logger.error("Validation failed: Missing landmarks")
                return nil
            }
            let deg = Float(180) / Float.pi
            let rollDeg = roll * deg
            let yawDeg = yaw * deg
            guard abs(rollDeg) <= maxRollDeg else {
                logger.error("Validation failed: Bad roll (\(rollDeg, privacy: .public) degrees)")
                return nil
            }
            guard abs(yawDeg) <= maxYawDeg else {
                logger.error("Validation failed: Bad yaw (\(yawDeg, privacy: .public) degrees)")
                return nil
            }

            let r = face.boundingBox
            guard min(r.width, r.height) >= minFaceLength else {
                logger.error("Validation failed: Face too small")
                return nil
            }

            let q = try faceCaptureQuality(on: image, face: face)
            guard q >= minQuality else {
                logger.error("Validation failed: Blurry face (quality: \(q, privacy: .public))")
                return nil
            }

            return face
        } catch {
            logger.error("Face detection/validation failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func faceCaptureQuality(on image: CIImage, face: VNFaceObservation) throws -> Float {
        let req = VNDetectFaceCaptureQualityRequest()
        req.inputFaceObservations = [face]

        let handler = VNImageRequestHandler(ciImage: image, orientation: .up, options: [:])
        try handler.perform([req])

        guard let obs = req.results?.first as? VNFaceObservation,
              let q = obs.faceCaptureQuality else {
            throw AppError(code: .faceValidationFailed)
        }
        return q
    }
}
