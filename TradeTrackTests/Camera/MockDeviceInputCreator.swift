import AVFoundation
@testable import TradeTrack

final class MockDeviceInputCreator: DeviceInputCreating {
    var nextInput: CaptureDeviceInputAbility?
    var errorToThrow: Error?
    var lastRequestedDevice: CaptureDeviceAbility?

    func makeInput(for device: CaptureDeviceAbility) throws -> CaptureDeviceInputAbility {
        lastRequestedDevice = device
        
        if let error = errorToThrow {
            throw error
        }
        
        guard let input = nextInput else {
            fatalError("MockDeviceInputCreator.nextInput not set")
        }
        return input
    }
}
