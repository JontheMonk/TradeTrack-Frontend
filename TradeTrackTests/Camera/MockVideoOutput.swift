import AVFoundation
@testable import TradeTrack

final class MockVideoOutput: VideoOutputting {

    // Track settings applied
    var videoSettings: [String : Any]! = [:]
    var alwaysDiscardsLateVideoFrames: Bool = false

    // Track delegate assignment
    private(set) var lastDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    private(set) var lastQueue: DispatchQueue?

    private(set) var requestedConnections: [AVMediaType] = []

    func connection(with mediaType: AVMediaType) -> AVCaptureConnection? {
        requestedConnections.append(mediaType)
        return nil
    }

    func setSampleBufferDelegate(
        _ sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?,
        queue: DispatchQueue?
    ) {
        lastDelegate = sampleBufferDelegate
        lastQueue = queue
    }
}
