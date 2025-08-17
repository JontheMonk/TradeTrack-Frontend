import Foundation
import Vision
import CoreImage
import CoreVideo

final class FaceValidator {
    // Tunables
    private let maxRollDeg: Float = 15
    private let maxYawDeg:  Float = 15
    private let minQuality: Float = 0.25
    private let minFaceLength: CGFloat = 0.20

    func validate(frame: FrameInput, face: VNFaceObservation) throws {
        // 1) Landmarks present (roll/yaw exist only when landmarks exist)
        guard let roll = face.roll?.floatValue, let yaw = face.yaw?.floatValue else {
            throw AppError(code: .faceValidationMissingLandmarks)
        }

        // 2) Pose checks
        let rollDeg = roll * 180 / .pi
        let yawDeg  = yaw  * 180 / .pi
        guard abs(rollDeg) <= maxRollDeg else { throw AppError(code: .faceValidationBadRoll) }
        guard abs(yawDeg)  <= maxYawDeg  else { throw AppError(code: .faceValidationBadYaw)  }

        let r = face.boundingBox
        guard min(r.width, r.height) >= minFaceLength else { throw AppError(code: .faceTooSmall) }

        // 4) Vision capture quality (frames are normalized to .up)
        let quality = try computeFaceQuality(from: frame.image, face: face)
        guard quality >= minQuality else { throw AppError(code: .faceValidationBlurry) }
    }

    private func computeFaceQuality(from image: CIImage,
                                    face: VNFaceObservation) throws -> Float {
        let req = VNDetectFaceCaptureQualityRequest()
        if #available(iOS 17.0, *) { req.revision = VNDetectFaceCaptureQualityRequestRevision3 }
        else { req.revision = VNDetectFaceCaptureQualityRequestRevision1 }
        req.inputFaceObservations = [face]

        // Image is already oriented to .up
        let handler = VNImageRequestHandler(ciImage: image, orientation: .up, options: [:])
        try handler.perform([req])

        guard let obs = req.results?.first as? VNFaceObservation,
              let q = obs.faceCaptureQuality else {
            throw AppError(code: .faceValidationQualityUnavailable)
        }
        return q
    }
}
