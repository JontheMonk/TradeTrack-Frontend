@testable import TradeTrack

struct MockCaptureDeviceInput: CaptureDeviceInputAbility {
    let captureDevice: CaptureDeviceAbility
    
    init(device: CaptureDeviceAbility) {
            self.captureDevice = device
        }
}
