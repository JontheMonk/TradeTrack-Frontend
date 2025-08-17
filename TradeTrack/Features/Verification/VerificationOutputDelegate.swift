import AVFoundation
import CoreImage

final class VerificationOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFrame: ((FrameInput) -> Void)?

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Build EXIF from rotation angle + mirroring (no deprecation warnings)
        let exif = CGImagePropertyOrientation(
            angleDegrees: connection.rotationAngleCompat,
            mirrored: connection.isVideoMirrored
        )

        // Normalize pixels to upright exactly once
        let ciUpright = CIImage(cvPixelBuffer: px)
            .oriented(forExifOrientation: Int32(exif.rawValue))

        let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        onFrame?(FrameInput(buffer: px, image: ciUpright, timestamp: ts))
    }
}

// MARK: - Compat + mapping (kept private to this file)

private extension AVCaptureConnection {
    /// iOS 17+: `videoRotationAngle`; older: map `videoOrientation` → angle.
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
