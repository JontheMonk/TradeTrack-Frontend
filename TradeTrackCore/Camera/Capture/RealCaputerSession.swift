import AVFoundation

/**
 `RealCaptureSession` is the concrete, hardware-backed implementation of
 `CaptureSessionProtocol`. It directly wraps an `AVCaptureSession` and is used
 **only** in real camera pipelines (never in unit tests).

 Because this type represents the real AVFoundation layer, it operates under
 strict invariants enforced by `CameraManager`:

   - All inputs added to the session are guaranteed to be real
     `AVCaptureDeviceInput` instances.
   - All outputs added to the session are guaranteed to be real
     `AVCaptureVideoDataOutput` instances.
   - Mocks never interact with `RealCaptureSession` — they use
     `MockCaptureSession` instead.

Given these guarantees, force casts (`as!`) are intentional and correct:
if a wrong type ever reaches this layer, that indicates a developer error
or a misconfigured dependency injection setup. Crashing immediately is the
right behavior, because the capture pipeline cannot continue safely without
real AVFoundation types.
*/
final class RealCaptureSession: CaptureSessionProtocol {

    private let underlyingSession = AVCaptureSession()
    
    var uiSession: AVCaptureSession {
            underlyingSession
        }
 
    /// Returns the real AVFoundation inputs. Force casting is correct because
    /// `CameraManager` only ever adds `AVCaptureDeviceInput` objects.
    var inputs: [CaptureDeviceInputProtocol] {
        underlyingSession.inputs.map { $0 as! CaptureDeviceInputProtocol }
    }

    /// Returns the real AVFoundation outputs. All outputs in a real session are
    /// guaranteed to be `AVCaptureVideoDataOutput`, which conforms to `VideoOutput`.
    var outputs: [VideoOutput] {
        underlyingSession.outputs.map { $0 as! VideoOutput }
    }

    var isRunning: Bool {
        underlyingSession.isRunning
    }

    /// Force-casting is intentional. In the real pipeline, inputs are always
    /// `AVCaptureInput` instances.
    func canAddInput(_ input: CaptureDeviceInputProtocol) -> Bool {
        let av = input as! AVCaptureInput
        return underlyingSession.canAddInput(av)
    }

    func addInput(_ input: CaptureDeviceInputProtocol) {
        let av = input as! AVCaptureInput
        underlyingSession.addInput(av)
    }

    func removeInput(_ input: CaptureDeviceInputProtocol) {
        let av = input as! AVCaptureInput
        underlyingSession.removeInput(av)
    }

    /// Force-casting is intentional. Only `AVCaptureVideoDataOutput` should ever
    /// be passed to this method in real usage.
    func canAddOutput(_ output: VideoOutput) -> Bool {
        let real = output as! AVCaptureVideoDataOutput
        return underlyingSession.canAddOutput(real)
    }

    func addOutput(_ output: VideoOutput) {
        let real = output as! AVCaptureVideoDataOutput
        underlyingSession.addOutput(real)
    }

    func beginConfiguration() {
        underlyingSession.beginConfiguration()
    }

    func commitConfiguration() {
        underlyingSession.commitConfiguration()
    }

    func startRunning() {
        underlyingSession.startRunning()
    }

    func stopRunning() {
        underlyingSession.stopRunning()
    }
}
