@testable import TradeTrackCore

/// Mock implementation of `CaptureDeviceInputProtocol`.
///
/// This test double simulates an `AVCaptureDeviceInput` without requiring
/// AVFoundation to create real hardware-backed inputs.
///
/// Usage:
///   - Inject into `MockCaptureSession.inputs` to simulate an existing input
///   - Verify that `CameraManager` correctly reuses, replaces, or removes inputs
///   - Control the `captureDevice` returned to test decision branches
///
/// Unlike the real `AVCaptureDeviceInput`, this mock is a simple wrapper and
/// provides no runtime behavior beyond holding the associated device.
final class MockCaptureDeviceInput: CaptureDeviceInputProtocol {
    
    /// The mock device associated with this input.
    /// Tests can supply any `CaptureDeviceProtocol` instance.
    let captureDevice: CaptureDeviceProtocol
    
    init(device: CaptureDeviceProtocol) {
        self.captureDevice = device
    }
}
