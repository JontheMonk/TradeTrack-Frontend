import AVFoundation

protocol CameraDeviceProvider {
    func defaultDevice(
        for deviceType: AVCaptureDevice.DeviceType,
        mediaType: AVMediaType?,
        position: AVCaptureDevice.Position
    ) -> CaptureDeviceAbility?

    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus

    func requestAccess(
        for mediaType: AVMediaType,
        completionHandler: @escaping (Bool) -> Void
    )
}
