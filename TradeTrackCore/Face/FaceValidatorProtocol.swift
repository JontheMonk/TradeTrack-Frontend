import Vision
import CoreImage

/// Contract for any component capable of validating whether a detected face
/// is suitable for further processing (embedding, backend matching, etc.).
///
/// This abstraction allows you to:
///   - mock the validator in tests
///   - swap implementations (e.g., lighter/faster validators)
///   - keep `FaceAnalyzer` decoupled from the validation strategy
///
/// Parameters checked by a validator may include:
///   - roll/yaw angles (is the face oriented correctly?)
///   - bounding-box size (is the face too small?)
///   - Vision capture-quality score (is the image sharp/bright enough?)
///
/// The `captureQualityProvider` closure is injected by the caller (usually
/// `FaceAnalyzer`) so `FaceValidator` does **not** depend directly on
/// Vision’s `VNDetectFaceCaptureQualityRequest`, which keeps the validator
/// testable and easier to mock.
protocol FaceValidatorProtocol {
    func isValid(
        face: VNFaceObservation,
        quality : Float
    ) -> Bool
}
