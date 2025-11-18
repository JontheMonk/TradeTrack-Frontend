import Vision
import CoreImage
import os.log

struct FaceValidator: FaceValidating {

    // MARK: - Thresholds
    var maxRollDeg: Float = 15
    var maxYawDeg: Float = 15
    var minQuality: Float = 0.25
    var minFaceLength: CGFloat = 0.20

    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "validator")

    func isValid(
        face: VNFaceObservation,
        in image: CIImage,
        captureQualityProvider: (VNFaceObservation, CIImage) throws -> Float
    ) -> Bool {

        // MARK: - Roll / Yaw
        guard let roll = face.roll?.floatValue,
              let yaw = face.yaw?.floatValue else {
            logger.debug("Rejected: missing roll/yaw")
            return false
        }

        let deg = Float(180) / .pi
        let rollDeg = abs(roll * deg)
        let yawDeg  = abs(yaw  * deg)

        guard rollDeg <= maxRollDeg else {
            logger.debug("Rejected: roll too high (\(rollDeg, privacy: .public)° > \(maxRollDeg))")
            return false
        }

        guard yawDeg <= maxYawDeg else {
            logger.debug("Rejected: yaw too high (\(yawDeg, privacy: .public)° > \(maxYawDeg))")
            return false
        }

        // MARK: - Face size
        let box = face.boundingBox
        let minSide = min(box.width, box.height)

        guard minSide >= minFaceLength else {
            logger.debug("Rejected: face too small (minSide \(minSide, privacy: .public) < \(minFaceLength))")
            return false
        }

        // MARK: - Capture quality
        do {
            let q = try captureQualityProvider(face, image)

            guard q >= minQuality else {
                logger.debug("Rejected: capture quality low (\(q, privacy:.public) < \(minQuality))")
                return false
            }

        } catch {
            logger.error("Rejected: capture quality provider threw error: \(error.localizedDescription, privacy: .public)")
            return false
        }

        logger.debug("Face accepted 👍")
        return true
    }
}
