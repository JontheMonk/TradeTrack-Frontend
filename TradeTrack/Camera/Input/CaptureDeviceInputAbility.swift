import AVFoundation

protocol CaptureDeviceInputAbility {
    var captureDevice: CaptureDeviceAbility { get }
}

extension AVCaptureDeviceInput: CaptureDeviceInputAbility {
    var captureDevice: CaptureDeviceAbility { self.device }
}

