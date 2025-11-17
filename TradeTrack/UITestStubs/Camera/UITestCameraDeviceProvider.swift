#if DEBUG
import AVFoundation

struct UITestCameraDeviceProvider: CameraDeviceProvider {
    let authorized: Bool
    func defaultDevice(for: AVCaptureDevice.DeviceType, mediaType: AVMediaType?, position: AVCaptureDevice.Position) -> AVCaptureDevice? { nil }
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus { authorized ? .authorized : .denied }
    func requestAccess(for mediaType: AVMediaType, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(authorized)
    }
}
#endif
