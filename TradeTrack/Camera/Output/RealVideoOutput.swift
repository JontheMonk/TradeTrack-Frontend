//
//  RealVideoOutput.swift
//
//  Concrete implementation of `VideoOutput` backed by
//  `AVCaptureVideoDataOutput`. This wrapper exists so that the camera pipeline
//  interacts only with a protocol (VideoOutput) rather than the concrete
//  AVFoundation type.
//
//  Benefits:
//  - allows full mocking of frame delivery in unit tests
//  - prevents UI/business logic from depending on AVFoundation
//  - keeps CameraManager highly testable and platform-agnostic
//

import AVFoundation

/// Production implementation of `VideoOutput` using `AVCaptureVideoDataOutput`.
///
/// `RealVideoOutput` exposes only the API surface the camera pipeline needs:
/// configuring video settings, toggling late-frame discard behavior,
/// setting delegates, and retrieving connections.
///
/// All other AVFoundation complexity stays encapsulated, and tests can supply
/// a mock `VideoOutput` instead of dealing with `CMSampleBuffer` or
/// real camera hardware.
final class RealVideoOutput: VideoOutput {

    /// The underlying AVFoundation output object.
    ///
    /// This is intentionally private so the rest of the app cannot access or
    /// mutate AVFoundation directly. All interactions go through the protocol.
    private let output = AVCaptureVideoDataOutput()

    // MARK: - Configuration

    /// Video settings for the output, such as pixel format.
    ///
    /// Mirrors `AVCaptureVideoDataOutput.videoSettings`.
    var videoSettings: [String : Any]! {
        get { output.videoSettings }
        set { output.videoSettings = newValue }
    }

    /// Whether late frames should be discarded.
    ///
    /// When true, AVFoundation avoids delivering frames that can’t be processed
    /// fast enough — useful for real-time camera pipelines like face tracking.
    var alwaysDiscardsLateVideoFrames: Bool {
        get { output.alwaysDiscardsLateVideoFrames }
        set { output.alwaysDiscardsLateVideoFrames = newValue }
    }

    // MARK: - Connections

    /// Returns the output’s connection for the specified media type.
    ///
    /// Used by `CameraManager` to configure mirroring, orientation, or
    /// rotation angle.
    func connection(with mediaType: AVMediaType) -> AVCaptureConnection? {
        output.connection(with: mediaType)
    }

    // MARK: - Delegation

    /// Assigns the sample buffer delegate to receive camera frames.
    ///
    /// - Parameters:
    ///   - sampleBufferDelegate: The object that processes video frames.
    ///   - queue: The dispatch queue on which the delegate will be called.
    ///
    /// `CameraManager` uses this to pipe frames into its face-analysis pipeline.
    func setSampleBufferDelegate(
        _ sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?,
        queue: DispatchQueue?
    ) {
        output.setSampleBufferDelegate(sampleBufferDelegate, queue: queue)
    }
}
