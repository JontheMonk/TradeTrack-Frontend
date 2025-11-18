import AVFoundation
import UIKit

final class CameraManager: CameraManaging {
    let session: CaptureSessioning
    private let output: VideoOutputting
    private let sessionQueue: DispatchQueue
    private let videoQueue: DispatchQueue
    private let deviceProvider: CameraDeviceProvider
    private let inputCreator : DeviceInputCreating
    

    init(
        deviceProvider: CameraDeviceProvider = RealCameraDeviceProvider(),
        session: CaptureSessioning = RealCaptureSession(),
        output: VideoOutputting = RealVideoOutput(),
        inputCreator: DeviceInputCreating = RealDeviceInputCreator(),
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

    func start<D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable>(delegate: D) async throws {
        try await onSessionQueue {
            try self.configureAndStart(delegate: delegate)
        }
    }

    func stop() {
        let session = self.session
        let output = self.output
        sessionQueue.async {
            if session.isRunning { session.stopRunning() }
            output.setSampleBufferDelegate(nil, queue: nil)
        }
    }

    // MARK: - Session queue bridge

    private func onSessionQueue<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { cont in
            sessionQueue.async {
                do { cont.resume(returning: try work()) }
                catch { cont.resume(throwing: error) }
            }
        }
    }

    // MARK: - Orchestration

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
            session.commitConfiguration()
            throw error
        }

        try startSession()
    }

    // MARK: - Device selection

    private func selectFrontDevice() throws -> CaptureDeviceAbility {
        if let d = deviceProvider.defaultDevice(for: .builtInTrueDepthCamera, mediaType: .video, position: .front) {
            return d
        }
        if let d = deviceProvider.defaultDevice(for: .builtInWideAngleCamera, mediaType: .video, position: .front) {
            return d
        }
        throw AppError(code: .cameraUnavailable)
    }

    // MARK: - Input
    private func ensureInput(for device: CaptureDeviceAbility) throws {
        // Reuse existing input if uniqueID matches
        if let _ = session.inputs
            .compactMap({$0})
            .first(where: { $0.captureDevice.uniqueID == device.uniqueID }) {
            return
        }

        // Remove old video inputs
        for input in session.inputs where input.captureDevice.hasMediaType(.video) {
            session.removeInput(input)
        }

        let input = try inputCreator.makeInput(for: device)
        guard session.canAddInput(input) else { throw AppError(code: .cameraInputFailed) }
        session.addInput(input)

    }
    
    // MARK: - Output

    private func ensureOutput() throws {
        // If this exact output object isn't already attached, add it.
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

    // MARK: - Start Session

    private func startSession() throws {
        session.startRunning()
        guard session.isRunning else { throw AppError(code: .cameraStartFailed) }
    }
}
