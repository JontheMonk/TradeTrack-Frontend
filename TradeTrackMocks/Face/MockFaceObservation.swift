import Vision
import CoreImage

/// Creates a configurable `VNFaceObservation` for use in unit tests.
///
/// - Parameters:
///   - bbox: Normalized bounding box in Vision coordinate space.
///   - roll: Optional roll angle in **radians**.
///   - yaw:  Optional yaw angle in **radians**.
///   - pitch: Optional pitch angle in **radians**.
/// - Returns: A `VNFaceObservation` preloaded with requested pose data.
func makeFace(
    bbox: CGRect = CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3),
    roll: Float? = nil,
    yaw: Float? = nil,
    pitch: Float? = nil
) -> VNFaceObservation {

    let obs = VNFaceObservation(boundingBox: bbox)

    // Inject pose data via KVC (safe for controlled test environments).
    if let r = roll {
        obs.setValue(NSNumber(value: r), forKey: "roll")
    }

    if let y = yaw {
        obs.setValue(NSNumber(value: y), forKey: "yaw")
    }
    
    if let p = pitch {
        obs.setValue(NSNumber(value: p), forKey: "pitch")
    }

    return obs
}
