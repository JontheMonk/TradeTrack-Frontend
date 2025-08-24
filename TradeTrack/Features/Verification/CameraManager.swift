@preconcurrency import AVFoundation
import UIKit

final class CameraManager {
    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session") // serial
    private let videoQueue   = DispatchQueue(label: "camera.frames")  // sample callbacks

    func requestAuthorization() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                throw AppError(code: .cameraNotAuthorized)
            }
        default:
            throw AppError(code: .cameraNotAuthorized)
        }
    }

    // MARK: Public API
    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(
        delegate: D
    ) async throws {
        try await onSessionQueue {
            try self.configureAndStart(delegate: delegate)
        }
    }

    func stop() {
        let session = self.session
        let output  = self.output
        sessionQueue.async {
            if session.isRunning { session.stopRunning() }
            output.setSampleBufferDelegate(nil, queue: nil)
        }
    }

    // MARK: Session queue bridge
    private func onSessionQueue<T>(
        _ work: @escaping () throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            sessionQueue.async {
                do   { cont.resume(returning: try work()) }
                catch { cont.resume(throwing: error) }
            }
        }
    }

    // MARK: Orchestration (runs on sessionQueue)
    private func configureAndStart<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(
            delegate: D) throws {
        if session.isRunning {
            applyDelegate(delegate)
            applyConnectionTuning()
            return
        }

        // Configure session
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

        // Start session after configuration
        try startSession()
    }

    // MARK: Building blocks (sessionQueue)
    private func selectFrontDevice() throws -> AVCaptureDevice {
        if let d = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) { return d }
        if let d = AVCaptureDevice.default(.builtInWideAngleCamera,  for: .video, position: .front) { return d }
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
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
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
