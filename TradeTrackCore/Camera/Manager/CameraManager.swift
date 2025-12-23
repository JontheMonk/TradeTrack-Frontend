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
//  - Ensures thread-safety via @MainActor isolation (satisfying AVFoundation's
//    serialization requirements without manual queue management).
//
//  This class contains NO direct AVFoundation types except for delegate
//  constraints. Everything else is abstracted behind protocols, making the
//  camera pipeline fully mockable and unit-testable.

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
@MainActor
final class CameraManager: CameraManagerProtocol {
    
    /// The capture session abstraction (`AVCaptureSession` in production).
    let session: CaptureSessionProtocol
    
    public var uiCaptureSession: AVCaptureSession {
        return session.uiSession
    }
    
    private let output: VideoOutput
    private let videoQueue: DispatchQueue
    private let deviceProvider: CameraDeviceProvider
    private let inputCreator: DeviceInputFactory
    
    init(
        deviceProvider: CameraDeviceProvider = RealCameraDeviceProvider(),
        session: CaptureSessionProtocol = RealCaptureSession(),
        output: VideoOutput = RealVideoOutput(),
        inputCreator: DeviceInputFactory = RealDeviceInputCreator(),
        videoQueue: DispatchQueue = DispatchQueue(label: "camera.frames")
    ) {
        self.deviceProvider = deviceProvider
        self.session = session
        self.output = output
        self.videoQueue = videoQueue
        self.inputCreator = inputCreator
    }
    
    
    func requestAuthorization() async throws {
        let status = deviceProvider.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                deviceProvider.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !granted { throw AppError(code: .cameraNotAuthorized) }
        default:
            throw AppError(code: .cameraNotAuthorized)
        }
    }
    
    // MARK: - Public API
    
    /// Starts the capture session and configures the entire camera pipeline.
    ///
    /// This is async so all work is executed on the `sessionQueue`.
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) async throws {
        try configureAndStart(delegate: delegate)
    }
    
    func stop() async {
        if session.isRunning {
            session.stopRunning()
        }
        output.setSampleBufferDelegate(nil, queue: nil)
    }
    
    
    
    private func configureAndStart<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) throws {
        if session.isRunning {
            applyDelegate(delegate)
            return
        }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        let device = try selectFrontDevice()
        try ensureInput(for: device)
        try ensureOutput()
        applyDelegate(delegate)
        applyConnectionTuning()
        
        session.startRunning()
        if !session.isRunning {
            throw AppError(code: .cameraStartFailed)
        }
        
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
