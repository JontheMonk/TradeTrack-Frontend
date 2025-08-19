import AVFoundation
import CoreImage

final class VerificationOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let onFrame: @Sendable (FrameInput) -> Void

    init(onFrame: @escaping @Sendable (FrameInput) -> Void) {
        self.onFrame = onFrame
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let exif = CGImagePropertyOrientation(
            angleDegrees: connection.rotationAngleCompat,
            mirrored: connection.isVideoMirrored
        )
        let ciUpright = CIImage(cvPixelBuffer: px)
            .oriented(forExifOrientation: Int32(exif.rawValue))
        let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        onFrame(FrameInput(image: ciUpright, timestamp: ts))
    }
}

extension VerificationOutputDelegate: @unchecked Sendable {}


// MARK: - Compat + mapping

private extension AVCaptureConnection {
    var rotationAngleCompat: CGFloat {
        if #available(iOS 17.0, *) { return videoRotationAngle }
        switch videoOrientation {
        case .portrait:            return 90
        case .portraitUpsideDown:  return 270
        case .landscapeRight:      return 0
        case .landscapeLeft:       return 180
        @unknown default:          return 0
        }
    }
}

private extension CGImagePropertyOrientation {
    init(angleDegrees: CGFloat, mirrored: Bool) {
        let a = (Int(round(angleDegrees)) % 360 + 360) % 360
        let base: CGImagePropertyOrientation = {
            switch a {
            case 0: return .up
            case 90: return .right
            case 180: return .down
            case 270: return .left
            default: return .up
            }
        }()
        self = mirrored
            ? (base == .up ? .upMirrored
               : base == .right ? .leftMirrored
               : base == .down ? .downMirrored
               : /* .left */     .rightMirrored)
            : base
    }
}
