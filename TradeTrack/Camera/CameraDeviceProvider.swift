import AVFoundation

/// Provides access to camera device functionality for CameraManager.
protocol CameraDeviceProvider {
    /// Returns the default device matching the specified criteria.
    func defaultDevice(for deviceType: AVCaptureDevice.DeviceType, mediaType: AVMediaType?, position: AVCaptureDevice.Position) -> AVCaptureDevice?

    /// Returns the current authorization status for the specified media type.
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus

    /// Requests access for the specified media type with a completion handler.
    func requestAccess(for mediaType: AVMediaType, completionHandler: @escaping (Bool) -> Void)
}
