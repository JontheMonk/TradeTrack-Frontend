//
//  CameraManager.swift
//
//  High–level orchestrator for the camera capture pipeline.
//
//  Responsibilities:
//  - Requests camera permission via CameraDeviceProvider
//  - Selects the appropriate capture device (TrueDepth > wide-angle)
//  - Creates inputs via DeviceInputFactory
//  - Manages a CaptureSessionProtocol (AVCaptureSession wrapper)
//  - Attaches and configures a VideoOutput for frame delivery
//  - Runs all AVFoundation work on a dedicated session queue
//
//  This class contains NO direct AVFoundation types except for delegate
//  constraints. Everything else is abstracted behind protocols, making the
//  camera pipeline fully mockable and unit-testable.
//

import AVFoundation
import UIKit

/// Concrete implementation of `CameraManagerProtocol`.
///
/// This type coordinates the entire camera pipeline:
/// - authorization
/// - device selection
/// - input setup
/// - output setup
/// - delegate wiring
/// - session lifecycle
///
/// AVFoundation requires all session mutations to occur on a dedicated serial
/// queue. `CameraManager` enforces this rule via `onSessionQueue(_:)`.
final class CameraManager: CameraManagerProtocol {

    /// The capture session abstraction (`AVCaptureSession` in production).
    let session: CaptureSessionProtocol

    /// Output responsible for delivering video frames to delegates.
    private let output: VideoOutput

    /// Serial queue for all AVFoundation session mutations.
    /// Ensures threadsafety and compliance with AVFoundation rules.
    private let sessionQueue: DispatchQueue

    /// Serial queue on which sample buffers are delivered to delegates.
    private let videoQueue: DispatchQueue

    /// Provides access to system camera devices and authorization APIs.
    private let deviceProvider: CameraDeviceProvider

    /// Factory that converts devices into session inputs.
    private let inputCreator: DeviceInputFactory
    

    // MARK: - Init

    /// Creates a complete camera pipeline with dependency injection.
    ///
    /// Tests supply mocked protocols; production uses concrete defaults.
    init(
        deviceProvider: CameraDeviceProvider = RealCameraDeviceProvider(),
        session: CaptureSessionProtocol = RealCaptureSession(),
        output: VideoOutput = RealVideoOutput(),
        inputCreator: DeviceInputFactory = RealDeviceInputCreator(),
        sessionQueue: DispatchQueue = DispatchQueue(label: "camera.session"),
        videoQueue: DispatchQueue = DispatchQueue(label: "camera.frames")
    ) {
        self.deviceProvider = deviceProvider
        self.session = session
        self.output = output
        self.sessionQueue = sessionQueue
        self.videoQueue = videoQueue
        self.inputCreator = inputCreator
    }
    

    // MARK: - Authorization

    /// Requests camera permission from the system.
    ///
    /// Uses `CameraDeviceProvider` so this can be mocked in tests.
    /// Throws `.cameraNotAuthorized` if permission is denied.
    func requestAuthorization() async throws {
        switch deviceProvider.authorizationStatus(for: .video) {

        case .authorized:
            return

        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                deviceProvider.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
            guard granted else { throw AppError(code: .cameraNotAuthorized) }

        default:
            throw AppError(code: .cameraNotAuthorized)
        }
    }

    // MARK: - Public API

    /// Starts the capture session and configures the entire camera pipeline.
    ///
    /// This is async so all work is executed on the `sessionQueue`.
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(
        delegate: D
    ) async throws {
        try await onSessionQueue {
            try self.configureAndStart(delegate: delegate)
        }
    }

    /// Stops the camera session and performs deterministic cleanup.
    ///
    /// This method is intentionally `async` so callers
    /// can await the completion of all teardown work before continuing.
    ///
    /// ### Concurrency model
    /// All interaction with the underlying capture session and video output
    /// is serialized onto `sessionQueue`. This guarantees exclusive access
    /// and prevents data races, even though the involved types are not
    /// `Sendable`.
    ///
    /// Swift concurrency cannot statically prove this queue confinement,
    /// which may result in Sendable-related warnings. These are safe and
    /// expected here because the serialization invariant is enforced
    /// by design.
    ///
    /// ### Behavior
    /// - Stops the capture session if it is currently running
    /// - Clears the sample buffer delegate
    /// - Resumes only after all cleanup has completed on `sessionQueue`
    ///
    /// Callers may safely assume that once this method returns, the camera
    /// pipeline is fully stopped and quiescent.
    func stop() async {
        let session = self.session
        let output = self.output

        await withCheckedContinuation { continuation in
            sessionQueue.async {
                if session.isRunning {
                    session.stopRunning()
                }
                output.setSampleBufferDelegate(nil, queue: nil)
                continuation.resume()
            }
        }
    }



    // MARK: - Session Queue Bridge

    /// Ensures all AVFoundation operations run on `sessionQueue`.
    private func onSessionQueue<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            sessionQueue.async {
                do { cont.resume(returning: try work()) }
                catch { cont.resume(throwing: error) }
            }
        }
    }


    // MARK: - Pipeline Orchestration

    /// Configures the session with the selected device, input, and output.
    private func configureAndStart<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(
        delegate: D
    ) throws {

        if session.isRunning {
            applyDelegate(delegate)
            applyConnectionTuning()
            return
        }

        session.beginConfiguration()
        do {
            let device = try selectFrontDevice()
            try ensureInput(for: device)
            try ensureOutput()
            applyDelegate(delegate)
            applyConnectionTuning()
            session.commitConfiguration()
        } catch {
            session.commitConfiguration()
            throw error
        }

        try startSession()
    }


    // MARK: - Device Selection

    /// Selects the best available front-facing camera.
    ///
    /// Prefers TrueDepth where available; falls back to wide-angle.
    private func selectFrontDevice() throws -> CaptureDeviceProtocol {
        if let d = deviceProvider.defaultDevice(
            for: .builtInTrueDepthCamera,
            mediaType: .video,
            position: .front
        ) {
            return d
        }
        if let d = deviceProvider.defaultDevice(
            for: .builtInWideAngleCamera,
            mediaType: .video,
            position: .front
        ) {
            return d
        }
        throw AppError(code: .cameraUnavailable)
    }


    // MARK: - Input Management

    /// Ensures the session has the correct input for the selected camera.
    private func ensureInput(for device: CaptureDeviceProtocol) throws {

        // Reuse existing input if device matches
        if session.inputs.contains(where: {
            $0.captureDevice.uniqueID == device.uniqueID
        }) {
            return
        }

        // Remove all old video inputs
        for input in session.inputs where input.captureDevice.hasMediaType(.video) {
            session.removeInput(input)
        }

        // Build input via factory
        let input: CaptureDeviceInputProtocol
        do {
            input = try inputCreator.makeInput(for: device)
        } catch {
            throw AppError(
                code: .cameraInputFailed,
                debugMessage: "Failed to create device input",
                underlyingError: error
            )
        }

        guard session.canAddInput(input) else {
            throw AppError(code: .cameraInputFailed)
        }

        session.addInput(input)
    }


    // MARK: - Output Management

    /// Ensures the video output is attached and configured.
    private func ensureOutput() throws {
        if !session.outputs.contains(where: { $0 === output }) {

            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
            output.alwaysDiscardsLateVideoFrames = true

            guard session.canAddOutput(output)
            else { throw AppError(code: .cameraOutputFailed) }

            session.addOutput(output)
        }
    }


    // MARK: - Delegate & Tuning

    /// Assigns the frame delegate and ensures frames are delivered on `videoQueue`.
    private func applyDelegate<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(
        _ delegate: D
    ) {
        output.setSampleBufferDelegate(delegate, queue: videoQueue)
    }

    /// Applies mirroring and orientation settings to the video connection.
    private func applyConnectionTuning() {
        guard let conn = output.connection(with: .video) else { return }
        conn.automaticallyAdjustsVideoMirroring = false
        conn.isVideoMirrored = true

        if #available(iOS 17.0, *) {
            let portraitAngle: CGFloat = 90
            if conn.isVideoRotationAngleSupported(portraitAngle) {
                conn.videoRotationAngle = portraitAngle
            }
        } else if conn.isVideoOrientationSupported {
            conn.videoOrientation = .portrait
        }
    }


    // MARK: - Start Session

    /// Starts the underlying AVFoundation session and verifies success.
    private func startSession() throws {
        session.startRunning()
        guard session.isRunning else {
            throw AppError(code: .cameraStartFailed)
        }
    }
}
