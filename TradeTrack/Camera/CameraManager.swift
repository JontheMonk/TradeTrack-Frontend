import AVFoundation
import UIKit

/// Manages the camera session and video output for the verification feature.
final class CameraManager : CameraManaging {
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session") // serial
    private let videoQueue = DispatchQueue(label: "camera.frames") // sample callbacks
    private let deviceProvider: CameraDeviceProvider

    /// Initializes the CameraManager with a device provider.
    /// - Parameter deviceProvider: The provider for camera device functionality (default is real implementation).
    init(deviceProvider: CameraDeviceProvider = RealCameraDeviceProvider()) {
        self.deviceProvider = deviceProvider
    }

    /// Requests camera authorization asynchronously.
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
            guard granted else {
                throw AppError(code: .cameraNotAuthorized)
            }
        default:
            throw AppError(code: .cameraNotAuthorized)
        }
    }

    // MARK: Public API
    /// Starts the camera session with the specified delegate.
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) async throws {
        try await onSessionQueue {
            try self.configureAndStart(delegate: delegate)
        }
    }

    /// Stops the camera session.
    func stop() {
        let session = self.session
        let output = self.output
        sessionQueue.async {
            if session.isRunning { session.stopRunning() }
            output.setSampleBufferDelegate(nil, queue: nil)
        }
    }

    // MARK: Session queue bridge
    private func onSessionQueue<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            sessionQueue.async {
                do { cont.resume(returning: try work()) }
                catch { cont.resume(throwing: error) }
            }
        }
    }

    // MARK: Orchestration (runs on sessionQueue)
    private func configureAndStart<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) throws {
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
            session.commitConfiguration() // Ensure configuration is committed even on error
            throw error
        }

        try startSession()
    }

    // MARK: Building blocks (sessionQueue)
    private func selectFrontDevice() throws -> AVCaptureDevice {
        if let d = deviceProvider.defaultDevice(for: .builtInTrueDepthCamera, mediaType: .video, position: .front) {
            return d
        }
        if let d = deviceProvider.defaultDevice(for: .builtInWideAngleCamera, mediaType: .video, position: .front) {
            return d
        }
        throw AppError(code: .cameraUnavailable)
    }

    private func ensureInput(for device: AVCaptureDevice) throws {
        if let current = session.inputs.compactMap({ $0 as? AVCaptureDeviceInput })
            .first(where: { $0.device.uniqueID == device.uniqueID }) {
            _ = current
            return
        }
        for input in session.inputs {
            if let di = input as? AVCaptureDeviceInput, di.device.hasMediaType(.video) {
                session.removeInput(di)
            }
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw AppError(code: .cameraInputFailed) }
        session.addInput(input)
    }

    private func ensureOutput() throws {
        if !session.outputs.contains(where: { $0 === output }) {
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
            output.alwaysDiscardsLateVideoFrames = true
            guard session.canAddOutput(output) else { throw AppError(code: .cameraOutputFailed) }
            session.addOutput(output)
        }
    }

    private func applyDelegate<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(_ delegate: D) {
        output.setSampleBufferDelegate(delegate, queue: videoQueue)
    }

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

    private func startSession() throws {
        session.startRunning()
        guard session.isRunning else { throw AppError(code: .cameraStartFailed) }
    }
}
