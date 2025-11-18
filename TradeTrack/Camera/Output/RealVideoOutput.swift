import AVFoundation

final class RealVideoOutput: VideoOutputting {
    private let output = AVCaptureVideoDataOutput()

    var underlyingOutput: AVCaptureOutput { output }

    var videoSettings: [String : Any]! {
        get { output.videoSettings }
        set { output.videoSettings = newValue }
    }

    var alwaysDiscardsLateVideoFrames: Bool {
        get { output.alwaysDiscardsLateVideoFrames }
        set { output.alwaysDiscardsLateVideoFrames = newValue }
    }

    func connection(with mediaType: AVMediaType) -> AVCaptureConnection? {
        output.connection(with: mediaType)
    }

    func setSampleBufferDelegate(
        _ sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?,
        queue: DispatchQueue?
    ) {
        output.setSampleBufferDelegate(sampleBufferDelegate, queue: queue)
    }
}
