import Vision
import CoreImage

/// Creates a VNFaceObservation that can be used for unit testing.
func makeFace(
    roll: Float?,
    yaw: Float?,
    boundingBox: CGRect = CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
) -> VNFaceObservation {

    // VNFaceObservation has no public init that sets roll/yaw
    let obs = VNFaceObservation(boundingBox: boundingBox)

    if let r = roll {
        obs.setValue(NSNumber(value: r), forKey: "roll")
    }

    if let y = yaw {
        obs.setValue(NSNumber(value: y), forKey: "yaw")
    }

    return obs
}
