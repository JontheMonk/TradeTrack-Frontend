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
/// It does **not** deliver real frames; for most unit tests of
/// `VerificationViewModel` you’ll either:
///   • call the internal `handle(_:)` via a helper/extension, or
///   • later build a tiny fake `VerificationOutputDelegate` that you drive manually.
final class MockCameraManager: CameraManagerProtocol {

    // MARK: - CameraManagerProtocol

    /// Backing session exposed to callers as `CaptureSessionProtocol`.
    /// Uses `MockCaptureSession` by default but can be overridden in tests.
    let session: CaptureSessionProtocol
    
    public var uiCaptureSession: AVCaptureSession {
        return session.uiSession
    }

    // MARK: - Configurable Behavior

    /// Controls whether `requestAuthorization()` succeeds.
    var authorizationGranted: Bool = true

    /// If set, `start(delegate:)` will throw this error instead of “starting”.
    var startShouldThrow: Error?

    // MARK: - Call Tracking

    /// Number of times `start(delegate:)` was called.
    private(set) var startCallCount = 0

    /// Number of times `stop()` was called.
    private(set) var stopCallCount = 0

    /// The last delegate passed into `start(delegate:)`.
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
        // Simulate the session having started.
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
