import AVFoundation
import TradeTrackCore

/// Mock implementation of `CaptureDeviceProtocol`.
///
/// This lightweight test double is used to simulate an `AVCaptureDevice`
/// without involving any actual hardware.
///
/// It allows tests to control:
///   - The device’s `uniqueID`
///   - Which media types the device claims to support
///
/// Common use cases:
///   - Testing input–selection logic in `CameraManager`
///   - Verifying that the correct device is reused or replaced
///   - Simulating devices that *don’t* support `.video`, triggering rejection paths
struct MockCaptureDevice: CaptureDeviceProtocol {

    /// The unique hardware ID returned through `captureDevice.uniqueID`.
    /// Tests often override this to verify input–reuse behavior.
    let uniqueID: String

    /// List of media types the mock should report as supported.
    /// Defaults to `[.video]`.
    let supportedMediaTypes: [AVMediaType]

    init(
        uniqueID: String = UUID().uuidString,
        supportedMediaTypes: [AVMediaType] = [.video]
    ) {
        self.uniqueID = uniqueID
        self.supportedMediaTypes = supportedMediaTypes
    }

    /// Returns `true` if the mock device reports supporting the given media type.
    func hasMediaType(_ mediaType: AVMediaType) -> Bool {
        supportedMediaTypes.contains(mediaType)
    }
}
