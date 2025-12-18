//
//  VideoOutput.swift
//
//  Protocol abstraction over `AVCaptureVideoDataOutput`, used to decouple
//  the camera pipeline from AVFoundation and enable full unit testing.
//
//  The concrete production implementation is `RealVideoOutput`, while
//  `AVCaptureVideoDataOutput` is made to conform via extension. Tests supply
//  mock implementations that simulate frame delivery without using real
//  camera hardware.
//

import AVFoundation

/// A lightweight interface for video-frame output handling.
///
/// `VideoOutput` abstracts the limited subset of `AVCaptureVideoDataOutput`
/// that the app depends on: configuring video settings, toggling late-frame
/// discard behavior, retrieving connections for orientation/mirroring, and
/// assigning sample buffer delegates.
///
/// This allows:
/// - `CameraManager` to operate without referencing AVFoundation directly
/// - mock outputs in unit tests (no real `CMSampleBuffer` flow required)
/// - cleaner DI and significantly easier testability
///
/// The production implementation is `RealVideoOutput`, but `AVCaptureVideoDataOutput`
/// also conforms so it can be injected directly if desired.
protocol VideoOutput: AnyObject {

    /// Dictionary of video settings used by the capture output.
    ///
    /// Common keys include pixel format type or compression options.
    /// Mirrors `AVCaptureVideoDataOutput.videoSettings`.
    var videoSettings: [String: Any]! { get set }

    /// Whether the output should discard frames if they arrive too quickly.
    ///
    /// Setting this to true avoids back-pressure in real-time camera pipelines.
    /// Mirrors `AVCaptureVideoDataOutput.alwaysDiscardsLateVideoFrames`.
    var alwaysDiscardsLateVideoFrames: Bool { get set }

    /// Returns the connection associated with a particular media type.
    ///
    /// Used by `CameraManager` to configure mirroring, orientation, or rotation.
    ///
    /// - Parameter mediaType: Typically `.video`.
    /// - Returns: The associated `AVCaptureConnection`, if present.
    func connection(with mediaType: AVMediaType) -> AVCaptureConnection?

    /// Assigns a delegate to receive video sample buffers.
    ///
    /// - Parameters:
    ///   - sampleBufferDelegate: The delegate receiving frame callbacks.
    ///   - queue: The queue on which the delegate is invoked.
    ///
    /// Equivalent to calling:
    /// `AVCaptureVideoDataOutput.setSampleBufferDelegate(_:queue:)`.
    ///
    /// Indirecting this behind a protocol makes it trivial to simulate
    /// frame-delivery behavior in tests without using AVFoundation.
    func setSampleBufferDelegate(
        _ sampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?,
        queue: DispatchQueue?
    )
}

/// Allows `AVCaptureVideoDataOutput` to be used directly as a `VideoOutput`.
extension AVCaptureVideoDataOutput: VideoOutput {}
