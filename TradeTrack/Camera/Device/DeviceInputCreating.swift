import AVFoundation

protocol DeviceInputCreating {
    func makeInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput
}
