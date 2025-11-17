import Vision
import CoreImage
import os.log

struct FaceValidator : FaceValidating {
    var maxRollDeg: Float = 15
    var maxYawDeg: Float = 15
    var minQuality: Float = 0.25
    var minFaceLength: CGFloat = 0.20

    func isValid(face: VNFaceObservation,
                 in image: CIImage,
                 captureQualityProvider: (VNFaceObservation, CIImage) throws -> Float)
    -> Bool {
        
        // --- Roll/Yaw ---
        guard let roll = face.roll?.floatValue,
              let yaw = face.yaw?.floatValue else { return false }

        let deg = Float(180) / .pi
        let rollDeg = abs(roll * deg)
        let yawDeg  = abs(yaw * deg)

        guard rollDeg <= maxRollDeg else { return false }
        guard yawDeg  <= maxYawDeg  else { return false }

        // --- Face size ---
        let r = face.boundingBox
        guard min(r.width, r.height) >= minFaceLength else { return false }

        // --- Capture quality ---
        do {
            let q = try captureQualityProvider(face, image)
            guard q >= minQuality else { return false }
        } catch {
            return false
        }

        return true
    }
}
