// MockCaptureSession.swift
import AVFoundation

/// Mock implementation of `CaptureSessionProtocol`.
///
/// This test double simulates an `AVCaptureSession` without requiring any
/// AVFoundation runtime behavior.
///
/// **Purpose**
/// - Lets tests control and observe session behavior deterministically.
/// - Verifies that `CameraManager` makes the correct sequence of calls:
///     - configuration begin/commit
///     - adding/removing inputs and outputs
///     - starting/stopping the session
/// - Allows failure injection for edge-case tests:
///     - `canAddInputResult` / `canAddOutputResult` to simulate configuration errors
///     - `shouldStartRunningSucceed` to simulate failed session startup
///
/// **Key Differences From Real Session**
/// - Does not interact with hardware.
/// - `isRunning` is controlled entirely by tests.
/// - Calls are recorded via boolean flags for verification.
final class MockCaptureSession: CaptureSessionProtocol {

    let uiSession = AVCaptureSession()
    // MARK: - Configurable Behavior

    /// Controls return value of `canAddInput(_:)`.
    var canAddInputResult: Bool = true

    /// Controls return value of `canAddOutput(_:)`.
    var canAddOutputResult: Bool = true

    /// Controls whether `startRunning()` succeeds (sets `isRunning = true`)
    /// or simulates failure (`isRunning = false`).
    var shouldStartRunningSucceed: Bool = true


    // MARK: - Call Tracking

    /// `true` if `beginConfiguration()` was invoked.
    private(set) var beginConfigurationCalled = false

    /// `true` if `commitConfiguration()` was invoked.
    private(set) var commitConfigurationCalled = false

    /// `true` if `startRunning()` was invoked.
    private(set) var startRunningCalled = false

    /// `true` if `stopRunning()` was invoked.
    private(set) var stopRunningCalled = false


    // MARK: - CaptureSessionProtocol Storage

    /// Simulated active inputs on the session.
    var inputs: [CaptureDeviceInputProtocol] = []

    /// Simulated active outputs on the session.
    var outputs: [VideoOutput] = []

    /// Whether the mock session is “running.”
    var isRunning: Bool = false


    // MARK: - CaptureSessionProtocol Implementation

    func canAddInput(_ input: CaptureDeviceInputProtocol) -> Bool {
        canAddInputResult
    }

    func addInput(_ input: CaptureDeviceInputProtocol) {
        inputs.append(input)
    }

    func removeInput(_ input: CaptureDeviceInputProtocol) {
        inputs.removeAll { lhs in
            (lhs as AnyObject) === (input as AnyObject)
        }
    }

    func canAddOutput(_ output: VideoOutput) -> Bool {
        canAddOutputResult
    }

    func addOutput(_ output: VideoOutput) {
        outputs.append(output)
    }

    func beginConfiguration() {
        beginConfigurationCalled = true
    }

    func commitConfiguration() {
        commitConfigurationCalled = true
    }

    func startRunning() {
        startRunningCalled = true
        isRunning = shouldStartRunningSucceed
    }

    func stopRunning() {
        stopRunningCalled = true
    }
}
