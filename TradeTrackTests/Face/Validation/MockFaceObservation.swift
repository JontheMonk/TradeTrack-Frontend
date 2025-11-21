import Vision
import CoreImage

/// Creates a configurable `VNFaceObservation` for use in unit tests.
///
/// This avoids needing Vision's real face detector, which would make tests slow,
/// non-deterministic, and dependent on actual image content.
/// Instead, tests can specify:
///
/// - `bbox`: The normalized bounding box (Vision coordinates, 0–1 range)
/// - `roll`: Optional face roll angle (in radians)
/// - `yaw`:  Optional face yaw angle (in radians)
///
/// Both `roll` and `yaw` are normally read-only on `VNFaceObservation`.
/// This helper injects them via KVC (`setValue(_:forKey:)`), which is safe
/// for controlled test environments and allows precise control over pose edge cases.
///
/// - Parameters:
///   - bbox: Normalized bounding box in Vision coordinate space (default 0.2–0.5 region).
///   - roll: Optional roll angle in **radians**.
///   - yaw:  Optional yaw angle in **radians**.
/// - Returns: A `VNFaceObservation` preloaded with the requested geometry and pose.
func makeFace(
    bbox: CGRect = CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3),
    roll: Float? = nil,
    yaw: Float? = nil
) -> VNFaceObservation {

    let obs = VNFaceObservation(boundingBox: bbox)

    // Inject roll/yaw via KVC (only for testing; these are read-only normally).
    if let r = roll {
        obs.setValue(NSNumber(value: r), forKey: "roll")
    }

    if let y = yaw {
        obs.setValue(NSNumber(value: y), forKey: "yaw")
    }

    return obs
}
