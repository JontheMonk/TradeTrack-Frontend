import AVFoundation

protocol VideoOutputting: AnyObject {
    var underlyingOutput: AVCaptureOutput { get }

    var videoSettings: [String: Any]! { get set }
    var alwaysDiscardsLateVideoFrames: Bool { get set }

    func connection(with mediaType: AVMediaType) -> AVCaptureConnection?
    func setSampleBufferDelegate(
        _ sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?,
        queue: DispatchQueue?
    )
}
