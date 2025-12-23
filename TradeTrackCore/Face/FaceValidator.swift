import Vision
import CoreImage
import os.log

/// Validates whether a detected face is suitable for recognition.
///
/// This struct applies a series of geometric + quality checks to ensure
/// the face is:
///   - upright enough (roll angle acceptable)
///   - facing forward enough (yaw within limits)
///   - large enough in the frame (bounding box not tiny)
///   - sharp/bright enough according to Vision’s capture-quality score
///
/// It does **not** detect the face or preprocess it. It only answers:
/// “Is this face worth embedding and sending to the backend?”
///
/// Why this exists:
/// ----------------
/// InsightFace models work *terribly* on badly angled, tiny, or blurry faces.
/// Without validation you get:
///   - false mismatches
///   - low confidence scores
///   - noisy embeddings
///
/// This validator prevents garbage from entering the pipeline.
///
/// The caller (`FaceAnalyzer`) supplies a closure for computing capture quality,
/// which allows the validator to stay testable and avoids tying it directly to
/// `VNDetectFaceCaptureQualityRequest`.
struct FaceValidator: FaceValidatorProtocol {
    
    // MARK: - Thresholds
    
    /// Maximum roll (head tilt) in degrees.
    var maxRollDeg: Float = 15
    
    /// Maximum yaw (looking sideways) in degrees.
    var maxYawDeg: Float = 15
    
    /// Maximum pitch (looking up/down) in degrees.
    var maxPitchDeg: Float = 20
    
    /// Minimum acceptable Vision `faceCaptureQuality` score.
    var minQuality: Float = 0.50
    
    /// Smallest acceptable normalized bounding-box side.
    /// (e.g. 0.20 means the face must cover at least 20% of the frame height/width.)
    var minFaceLength: CGFloat = 0.20
    
    /// Vision sometimes spits out angles like 15.000019 — this prevents false rejects.
    private let angleEpsilon: Float = 0.0002
    
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "validator")
    
    /// Returns `true` only if the face meets all geometric + quality requirements.
    ///
    /// - Parameters:
    ///   - face: The `VNFaceObservation` to validate.
    ///   - image: The full `CIImage` frame (used for quality estimation).
    ///   - captureQualityProvider: A closure that takes the face + image and returns a
    ///     Vision capture-quality score, or throws.
    func isValid(
        face: VNFaceObservation,
        quality : Float
    ) -> Bool {
        
        // MARK: - Roll / Yaw
        
        guard let roll = face.roll?.floatValue,
              let yaw  = face.yaw?.floatValue,
              let pitch = face.pitch?.floatValue else {
            logger.debug("Rejected: missing pitch/roll/yaw")
            return false
        }
        
        let deg = Float(180) / .pi
        let rollDeg = abs(roll * deg)
        let yawDeg  = abs(yaw  * deg)
        let pitchDeg = abs(pitch * deg)
        
        guard rollDeg <= maxRollDeg + angleEpsilon else {
            logger.debug("Rejected: roll too high (\(rollDeg)° > \(maxRollDeg))")
            return false
        }
        
        guard yawDeg <= maxYawDeg + angleEpsilon else {
            logger.debug("Rejected: yaw too high (\(yawDeg)° > \(maxYawDeg))")
            return false
        }
        

        guard pitchDeg <= maxPitchDeg + angleEpsilon else {
            logger.debug("Rejected: pitch too high (\(pitchDeg)° > \(maxPitchDeg))")
            return false
        }
        
        // MARK: - Face size
        
        let box = face.boundingBox
        let minSide = min(box.width, box.height)
        
        guard minSide >= minFaceLength else {
            logger.debug("Rejected: face too small (minSide \(minSide) < \(minFaceLength))")
            return false
        }
        
        // MARK: - Capture Quality
        
        do {
            
            guard quality >= minQuality else {
                logger.debug("Rejected: capture quality low (\(quality) < \(minQuality))")
                return false
            }
            
            logger.debug("Face accepted")
            return true
        }
    }
}
