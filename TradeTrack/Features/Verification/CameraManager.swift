import AVFoundation
import UIKit

final class CameraManager {
    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "camera.frames")

    func requestAuthorization() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                throw AppError(code: .cameraNotAuthorized)
            }
        default: throw AppError(code: .cameraNotAuthorized)
        }
    }

    func start(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) throws {
        guard !session.isRunning else { return }

        guard let device =
            AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) ??
            AVCaptureDevice.default(.builtInWideAngleCamera,  for: .video, position: .front)
        else { throw AppError(code: .cameraUnavailable) }

        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard session.canAddInput(input) else { session.commitConfiguration(); throw AppError(code: .cameraInputFailed) }
        session.addInput(input)

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(delegate, queue: videoQueue)

        guard session.canAddOutput(output) else { session.commitConfiguration(); throw AppError(code: .cameraOutputFailed) }
        session.addOutput(output)

        if let conn = output.connection(with: .video) {
            conn.automaticallyAdjustsVideoMirroring = false
            conn.isVideoMirrored = true
            if #available(iOS 17.0, *) {
                let portraitAngle: CGFloat = 90
                if conn.isVideoRotationAngleSupported(portraitAngle) { conn.videoRotationAngle = portraitAngle }
            } else {
                conn.videoOrientation = .portrait
            }
        }

        session.commitConfiguration()
        session.startRunning()
        guard session.isRunning else { throw AppError(code: .cameraStartFailed) }
    }

    func stop() {
        if session.isRunning { session.stopRunning() }
        output.setSampleBufferDelegate(nil, queue: nil)
    }
}
