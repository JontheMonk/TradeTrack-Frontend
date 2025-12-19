//
//  CaptureSessionProtocol.swift
//
//  Abstraction over AVCaptureSession.
//  Allows the camera pipeline to be unit-tested without AVFoundation.
//  Implemented by AVCaptureSession via an extension, and by mocks in tests.
//

import AVFoundation

/// A testable interface that mirrors the core functionality of `AVCaptureSession`.
///
/// This protocol exists so the camera pipeline can be isolated from AVFoundation
/// during testing. Instead of depending directly on `AVCaptureSession`, components
/// like `CameraManager` depend on `CaptureSessionProtocol`, which can be backed by:
///
/// - a real `AVCaptureSession` in production
/// - a lightweight mock session in unit tests
///
/// The API intentionally reflects the subset of `AVCaptureSession` features used by
/// the app: managing inputs/outputs, configuring session state, and starting/stopping
/// capture.
protocol CaptureSessionProtocol: AnyObject {
    
    var uiSession: AVCaptureSession { get }
    
    /// The current list of device inputs added to the session.
    /// Mirrors `AVCaptureSession.inputs`.
    var inputs: [CaptureDeviceInputProtocol] { get }

    /// The current list of outputs added to the session.
    /// Mirrors `AVCaptureSession.outputs`.
    var outputs: [VideoOutput] { get }

    /// Indicates whether the underlying session is currently running.
    /// Equivalent to `AVCaptureSession.isRunning`.
    var isRunning: Bool { get }
    
    // MARK: - Input Management

    /// Returns whether this input can be added to the session.
    /// Matches `AVCaptureSession.canAddInput(_:)`.
    func canAddInput(_ input: CaptureDeviceInputProtocol) -> Bool

    /// Adds a device input to the session.
    /// Matches `AVCaptureSession.addInput(_:)`.
    func addInput(_ input: CaptureDeviceInputProtocol)

    /// Removes an existing device input from the session.
    func removeInput(_ input: CaptureDeviceInputProtocol)

    // MARK: - Output Management

    /// Returns whether this output can be added to the session.
    /// Matches `AVCaptureSession.canAddOutput(_:)`.
    func canAddOutput(_ output: VideoOutput) -> Bool

    /// Adds a video output to the session.
    func addOutput(_ output: VideoOutput)

    // MARK: - Configuration

    /// Begins a batch configuration block.
    /// Must be paired with `commitConfiguration()`.
    ///
    /// Equivalent to `AVCaptureSession.beginConfiguration()`.
    func beginConfiguration()

    /// Ends a configuration block and applies pending changes.
    ///
    /// Equivalent to `AVCaptureSession.commitConfiguration()`.
    func commitConfiguration()

    // MARK: - Lifecycle

    /// Starts running the capture session.
    func startRunning()

    /// Stops running the capture session.
    func stopRunning()
}
