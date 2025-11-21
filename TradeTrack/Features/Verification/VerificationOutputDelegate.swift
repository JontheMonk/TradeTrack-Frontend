import AVFoundation
import CoreImage

/// A lightweight delegate that extracts frames from an `AVCaptureVideoDataOutput`
/// and forwards them as `CIImage`s to a caller-provided closure.
///
/// This keeps `AVCaptureVideoDataOutputSampleBufferDelegate` out of your view models
/// and avoids passing AVFoundation details through your app.
///
/// Typical usage:
/// ```swift
/// let delegate = VerificationOutputDelegate { ciImage in
///     Task { await viewModel.handle(ciImage) }
/// }
/// output.setSampleBufferDelegate(delegate, queue: .main)
/// ```
final class VerificationOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    /// Closure invoked for every captured frame.
    /// Runs on whichever dispatch queue the caller assigns
    /// when setting this object as the sample buffer delegate.
    private let onFrame: @Sendable (CIImage) -> Void

    /// Creates a delegate that forwards each video frame to `onFrame`.
    ///
    /// - Parameter onFrame: Closure that receives the converted `CIImage`.
    init(onFrame: @escaping @Sendable (CIImage) -> Void) {
        self.onFrame = onFrame
    }

    /// AVFoundation callback — extracts a pixel buffer and converts it to `CIImage`.
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        guard let px = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: px)
        onFrame(ci)
    }
}

/// Declare `Sendable` manually since AVFoundation delegates
/// can’t safely conform automatically. This is fine because the
/// delegate doesn't mutate shared state.
extension VerificationOutputDelegate: @unchecked Sendable {}
