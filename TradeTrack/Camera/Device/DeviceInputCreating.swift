import AVFoundation

protocol DeviceInputCreating {
    func makeInput(for device: CaptureDeviceAbility) throws -> CaptureDeviceInputAbility
}




