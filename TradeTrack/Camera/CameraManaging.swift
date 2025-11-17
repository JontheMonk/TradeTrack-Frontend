import AVFoundation

protocol CameraManaging {
    func requestAuthorization() async throws
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) async throws
    func stop()
}
