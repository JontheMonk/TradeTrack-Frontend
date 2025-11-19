@testable import TradeTrack

final class MockCaptureDeviceInput: CaptureDeviceInputAbility {
    let captureDevice: CaptureDeviceAbility
    
    init(device: CaptureDeviceAbility) {
            self.captureDevice = device
        }
}
