#if DEBUG
import AVFoundation


final class NoopCameraManager: CameraManaging {
    var session: AVCaptureSession { AVCaptureSession() } 
    func requestAuthorization() async throws {}
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) async throws {}
    func stop() {}
}
#endif
