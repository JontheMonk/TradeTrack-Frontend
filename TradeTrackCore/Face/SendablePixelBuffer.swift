import AVFoundation

/// A Sendable wrapper for CVPixelBuffer to satisfy Swift 6 concurrency requirements.
struct SendablePixelBuffer: @unchecked Sendable {
    let buffer: CVPixelBuffer
}
