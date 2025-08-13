import AVFoundation

/// Nonisolated delegate that just pipes frames out.
/// (No UI touches, no heavy work here.)
final class VerificationOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFrame: ((CMSampleBuffer) -> Void)?

    // Optional: throttle inside the delegate so your VM doesn’t even see excess frames
    private let throttle: TimeInterval
    private var last = Date.distantPast

    init(throttle: TimeInterval = 1.0) {
        self.throttle = throttle
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = Date()
        if now.timeIntervalSince(last) < throttle { return }
        last = now
        onFrame?(sampleBuffer)
    }
}
