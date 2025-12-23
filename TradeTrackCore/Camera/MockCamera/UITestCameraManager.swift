import Foundation
import AVFoundation

/// Camera manager used exclusively for UI tests.
///
/// This implementation does not interact with AVFoundation.
/// Instead, it emits deterministic, high-level camera outcomes
/// based on the selected `CameraWorld`.
///
/// Its purpose is to drive UI state transitions, not to simulate
/// camera mechanics.
@MainActor
final class UITestCameraManager: CameraManagerProtocol {

    // Use the MockCaptureSession instead of a Null one
    private let mockSession = MockCaptureSession()
    
    /// Publicly exposed via the protocol for the ViewModel/UI
    public var uiCaptureSession: AVCaptureSession {
        return mockSession.uiSession
    }

    private let world: CameraWorld
    private(set) var isRunning = false

    // MARK: - Init

    init(world: CameraWorld) {
        self.world = world
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        if world == .cameraUnavailable {
            throw AppError(code: .cameraNotAuthorized)
        }
    }

    // MARK: - Start

    func start<D>(
        delegate: D
    ) async throws
    where D: AVCaptureVideoDataOutputSampleBufferDelegate & Sendable {

        isRunning = true

        // Immediately drive UI-visible outcomes.
        // No timing, no frames, no delegates.
        emitInitialState()
    }

    // MARK: - Stop

    func stop() async {
        isRunning = false
    }

    // MARK: - Private helpers

    private func emitInitialState() {
        switch world {
        case .noFace:
            NotificationCenter.default.post(
                name: .uiTestCameraNoFace,
                object: nil
            )

        case .invalidFace:
            NotificationCenter.default.post(
                name: .uiTestCameraInvalidFace,
                object: nil
            )

        case .validFace:
            NotificationCenter.default.post(
                name: .uiTestCameraValidFace,
                object: nil
            )

        case .cameraUnavailable:
            break
        }
    }
}
