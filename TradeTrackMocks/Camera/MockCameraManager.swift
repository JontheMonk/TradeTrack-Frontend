import Foundation
import AVFoundation
@testable import TradeTrackCore

/// Test double for `CameraManagerProtocol`.
///
/// This mock avoids any real AVFoundation work and instead:
///  - lets tests control authorization outcome
///  - tracks whether `start` / `stop` were called
///  - exposes a mock capture session for inspection
///
/// This mock is best for testing UI states (e.g., "What happens if camera access is denied?").
/// If you need to test the actual image processing pipeline with real pixels,
/// use `VideoFileCameraManager` instead.
@MainActor
final class MockCameraManager: CameraManagerProtocol {

    // MARK: - CameraManagerProtocol Requirements

    let session: CaptureSessionProtocol
    
    public var uiCaptureSession: AVCaptureSession {
        return session.uiSession
    }

    // MARK: - Configurable Behavior

    var authorizationGranted: Bool = true
    var startShouldThrow: Error?

    // MARK: - Call Tracking

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var lastDelegate: (any AVCaptureVideoDataOutputSampleBufferDelegate)?

    // MARK: - Init

    init(session: CaptureSessionProtocol = MockCaptureSession()) {
        self.session = session
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        if !authorizationGranted {
            throw AppError(code: .cameraNotAuthorized)
        }
    }

    // MARK: - Start

    func start<D>(
        delegate: D
    ) async throws where D : AVCaptureVideoDataOutputSampleBufferDelegate & Sendable {
        startCallCount += 1

        if let error = startShouldThrow {
            throw error
        }

        lastDelegate = delegate
        
        // Safely update the mock session state
        if let mockSession = session as? MockCaptureSession {
            mockSession.isRunning = true
        }
    }

    // MARK: - Stop

    func stop() async {
        stopCallCount += 1

        if let mockSession = session as? MockCaptureSession {
            mockSession.isRunning = false
        }

        lastDelegate = nil
    }
}
