import AVFoundation

final class RealDeviceInputCreator: DeviceInputCreating {
    func makeInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        try AVCaptureDeviceInput(device: device)
    }
}
