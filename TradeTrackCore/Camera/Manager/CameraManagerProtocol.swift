//
//  CameraManagerProtocol.swift
//
//  High-level interface for controlling the camera pipeline.
//  Defines the public API used by UI layers (e.g. SwiftUI views) without
//  exposing any AVFoundation details.
//
//  The concrete implementation is `CameraManager`, but tests use mocks that
//  conform to this protocol, allowing deterministic, hardware-free testing.
//

import AVFoundation

/// Public interface for managing camera authorization, session lifecycle,
/// and frame delivery.
///
/// `CameraManagerProtocol` abstracts the entire camera system so UI components
/// (e.g. `VerificationViewModel`, `RegisterFaceViewModel`) can depend on a
/// stable, testable API without importing AVFoundation or touching hardware.
///
/// Conforming types must:
/// - request permission before starting
/// - configure and start a capture session
/// - deliver frames via a delegate passed to `start(delegate:)`
/// - support clean asynchronous stopping (important for testing)
@MainActor
public protocol CameraManagerProtocol {

    var uiCaptureSession: AVCaptureSession { get }
    
    /// Requests camera access from the system.
    ///
    /// - Throws: `.cameraNotAuthorized` if access is denied or restricted.
    ///
    /// Must be called before `start(delegate:)`.
    func requestAuthorization() async throws

    /// Starts the camera session and begins delivering frames to `delegate`.
    ///
    /// The delegate receives `CMSampleBuffer`s on a dedicated video queue.
    ///
    /// - Parameter delegate: An object that implements
    ///   `AVCaptureVideoDataOutputSampleBufferDelegate` and is marked `Sendable`.
    ///
    /// - Throws: Errors related to device selection, input/output creation,
    ///   or session startup.
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(
        delegate: D
    ) async throws

    /// Stops the camera session and clears the output delegate.
    ///
    /// This method is `async` so callers can await cleanup work performed on
    /// the dedicated session queue, ensuring deterministic test behavior.
    func stop() async
}
