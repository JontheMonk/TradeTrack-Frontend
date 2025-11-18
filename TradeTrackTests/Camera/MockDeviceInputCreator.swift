import AVFoundation
@testable import TradeTrack

final class MockDeviceInputCreator: DeviceInputCreating {
    var nextInput: AVCaptureDeviceInput?
    var errorToThrow: Error?

    func makeInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        if let error = errorToThrow { throw error }
        return nextInput! // controlled by test
    }
}
