import AVFoundation

protocol CameraManaging {
    var session: CaptureSessioning { get }
    func requestAuthorization() async throws
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) async throws
    func stop()
}
