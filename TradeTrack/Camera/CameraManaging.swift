import AVFoundation

protocol CameraManaging {
    var session: AVCaptureSession { get }
    func requestAuthorization() async throws
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) async throws
    func stop()
}
