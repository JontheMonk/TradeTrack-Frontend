import AVFoundation
import CoreImage

final class VerificationOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let onFrame: @Sendable (CIImage) -> Void

    init(onFrame: @escaping @Sendable (CIImage) -> Void) {
        self.onFrame = onFrame
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        onFrame(CIImage(cvPixelBuffer: px))
    }
}

extension VerificationOutputDelegate: @unchecked Sendable {}
