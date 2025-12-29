import AVFoundation
import TradeTrackCore

/// Mock implementation of `CameraDeviceProvider`.
///
/// Used to simulate:
///   - Front-camera availability (`defaultDeviceToReturn`)
///   - Authorization states (`authorizationStatusToReturn`)
///   - User responses to permission prompts (`requestAccessResult`)
///
/// The mock also records all calls made by `CameraManager` so tests can assert:
///   - Which device types were queried
///   - How many times authorization was checked
///   - Whether requestAccess was invoked
final class MockCameraDeviceProvider: CameraDeviceProvider {

    /// Device returned for all `defaultDevice(...)` requests.
    /// Tests swap this to simulate TrueDepth/WideAngle availability.
    var defaultDeviceToReturn: CaptureDeviceProtocol? = nil

    /// Authorization status to return from `authorizationStatus(...)`.
    var authorizationStatusToReturn: AVAuthorizationStatus = .notDetermined

    /// Result passed to the requestAccess completion handler.
    var requestAccessResult: Bool = false

    // MARK: - Call Recording

    /// Tracks all calls to `defaultDevice(...)` for verification.
    private(set) var defaultDeviceCalls: [(type: AVCaptureDevice.DeviceType,
                                          media: AVMediaType?,
                                          pos: AVCaptureDevice.Position)] = []

    /// Tracks calls to `authorizationStatus(...)`.
    private(set) var authorizationStatusCalls: [AVMediaType] = []

    /// Tracks calls to `requestAccess(...)`.
    private(set) var requestAccessCalls: [AVMediaType] = []

    // MARK: - Protocol Implementation

    func defaultDevice(
        for deviceType: AVCaptureDevice.DeviceType,
        mediaType: AVMediaType?,
        position: AVCaptureDevice.Position
    ) -> CaptureDeviceProtocol? {
        defaultDeviceCalls.append((deviceType, mediaType, position))
        return defaultDeviceToReturn
    }

    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        authorizationStatusCalls.append(mediaType)
        return authorizationStatusToReturn
    }

    func requestAccess(
        for mediaType: AVMediaType,
        completionHandler: @escaping (Bool) -> Void
    ) {
        requestAccessCalls.append(mediaType)
        completionHandler(requestAccessResult)
    }
}
