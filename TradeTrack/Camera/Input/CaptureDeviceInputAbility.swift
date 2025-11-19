import AVFoundation

protocol CaptureDeviceInputAbility : AnyObject {
    var captureDevice: CaptureDeviceAbility { get }
}

extension AVCaptureDeviceInput: CaptureDeviceInputAbility {
    var captureDevice: CaptureDeviceAbility { self.device }
}

