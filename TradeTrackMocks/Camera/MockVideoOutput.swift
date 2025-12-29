import AVFoundation
import TradeTrackCore

/// A test double for `AVCaptureVideoDataOutput` conforming to `VideoOutput`.
///
/// This mock lets tests assert how `CameraManager` interacts with the video output:
///   - Whether the delegate is assigned (`lastDelegate`, `lastQueue`)
///   - Whether video settings are applied correctly (`videoSettings`)
///   - Whether the manager requests a connection (`requestedConnections`)
///
/// Why this exists:
/// ----------------
/// `AVCaptureVideoDataOutput` is tightly coupled to the device’s camera hardware.
/// Unit tests cannot safely instantiate or mutate real AVFoundation pipeline objects.
///
/// `MockVideoOutput` gives us a predictable, isolated environment that captures
/// interactions without touching real camera components.
///
/// Typical usage in tests:
/// ------------------------
/// ```swift
/// let output = MockVideoOutput()
/// let sut = CameraManager(..., output: output, ...)
///
/// try await sut.start(delegate: DummyDelegate())
///
/// XCTAssertTrue(output.lastDelegate is DummyDelegate)
/// XCTAssertNotNil(output.lastQueue)
/// XCTAssertEqual(output.requestedConnections, [.video])
/// ```
final class MockVideoOutput: VideoOutput {
    /// Satisfies the VideoOutput protocol requirement.
    /// Returns a dummy instance so the CaptureSession doesn't crash
    /// during unit/UI tests.
    var asAVOutput: AVCaptureOutput {
        return AVCaptureVideoDataOutput()
    }
    // MARK: - Configuration tracking
    
    /// Captures the last video settings applied by the system under test.
    /// Defaults to an empty dictionary.
    var videoSettings: [String : Any]! = [:]

    /// Tracks whether the session attempted to enable late-frame discarding.
    var alwaysDiscardsLateVideoFrames: Bool = false

    // MARK: - Delegate tracking
    
    /// The most recent sample buffer delegate assigned by the system under test.
    private(set) var lastDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    /// The queue passed alongside `lastDelegate`.
    private(set) var lastQueue: DispatchQueue?

    // MARK: - Connection tracking
    
    /// A history of media types for which the system requested connections.
    /// Useful for asserting that `.video` is queried.
    private(set) var requestedConnections: [AVMediaType] = []

    /// Records the request for a connection and always returns `nil`
    /// (the mock does not simulate real connections).
    func connection(with mediaType: AVMediaType) -> AVCaptureConnection? {
        requestedConnections.append(mediaType)
        return nil
    }

    /// Captures the delegate and queue assigned by the system under test.
    func setSampleBufferDelegate(
        _ sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?,
        queue: DispatchQueue?
    ) {
        lastDelegate = sampleBufferDelegate
        lastQueue = queue
    }
}
