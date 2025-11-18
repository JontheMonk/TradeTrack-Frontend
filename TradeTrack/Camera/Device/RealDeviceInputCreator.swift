import AVFoundation

final class RealDeviceInputCreator: DeviceInputCreating {
    func makeInput(for device: CaptureDeviceAbility) throws -> CaptureDeviceInputAbility {

        guard let avDevice = device as? AVCaptureDevice else {
            fatalError("RealDeviceInputCreator expects real AVCaptureDevice")
        }

        let input = try AVCaptureDeviceInput(device: avDevice)
        return input
    }
}


