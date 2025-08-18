import Vision
import CoreImage

final class FaceValidator {
    // Tunables
    private let maxRollDeg: Float = 15
    private let maxYawDeg:  Float = 15
    private let minQuality: Float = 0.25
    private let minFaceLength: CGFloat = 0.20 // min(r.width, r.height) in normalized coords

    /// `image` must already be oriented to `.up`.
    func validate(image: CIImage, face: VNFaceObservation) throws {
        guard let roll = face.roll?.floatValue, let yaw = face.yaw?.floatValue else {
            throw AppError(code: .faceValidationMissingLandmarks)
        }
        let deg = Float(180) / Float.pi
        let rollDeg = roll * deg
        let yawDeg  = yaw  * deg
        guard abs(rollDeg) <= maxRollDeg else { throw AppError(code: .faceValidationBadRoll) }
        guard abs(yawDeg)  <= maxYawDeg  else { throw AppError(code: .faceValidationBadYaw)  }

        let r = face.boundingBox
        guard min(r.width, r.height) >= minFaceLength else { throw AppError(code: .faceTooSmall) }

        let q = try faceCaptureQuality(on: image, face: face)
        guard q >= minQuality else { throw AppError(code: .faceValidationBlurry) }
    }

    private func faceCaptureQuality(on image: CIImage, face: VNFaceObservation) throws -> Float {
        let req = VNDetectFaceCaptureQualityRequest()
        req.inputFaceObservations = [face]

        let handler = VNImageRequestHandler(ciImage: image, orientation: .up, options: [:])
        try handler.perform([req])

        guard let obs = req.results?.first as? VNFaceObservation,
              let q = obs.faceCaptureQuality else {
            throw AppError(code: .faceValidationQualityUnavailable)
        }
        return q
    }
}
