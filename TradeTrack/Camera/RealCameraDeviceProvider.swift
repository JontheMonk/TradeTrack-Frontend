import AVFoundation

/// Real implementation of CameraDeviceProvider using AVCaptureDevice.
class RealCameraDeviceProvider: CameraDeviceProvider {
    func defaultDevice(for deviceType: AVCaptureDevice.DeviceType, mediaType: AVMediaType?, position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(deviceType, for: mediaType, position: position)
    }

    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: mediaType)
    }

    func requestAccess(for mediaType: AVMediaType, completionHandler: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: mediaType, completionHandler: completionHandler)
    }
}
