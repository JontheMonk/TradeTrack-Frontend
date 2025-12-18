import Foundation
import AVFoundation

/// A no-op capture session used by UI tests.
///
/// This implementation satisfies `CaptureSessionProtocol` without
/// performing any real AVFoundation work. All operations are inert
/// and deterministic.
final class NullCaptureSession: CaptureSessionProtocol {

    // MARK: - Stored Properties

    var inputs: [any CaptureDeviceInputProtocol] = []
    var outputs: [any VideoOutput] = []
    var isRunning: Bool = false

    // MARK: - Input Management

    func canAddInput(_ input: any CaptureDeviceInputProtocol) -> Bool {
        false
    }

    func addInput(_ input: any CaptureDeviceInputProtocol) {
        // no-op
    }

    func removeInput(_ input: any CaptureDeviceInputProtocol) {
        // no-op
    }

    // MARK: - Output Management

    func canAddOutput(_ output: any VideoOutput) -> Bool {
        false
    }

    func addOutput(_ output: any VideoOutput) {
        // no-op
    }

    // MARK: - Configuration

    func beginConfiguration() {
        // no-op
    }

    func commitConfiguration() {
        // no-op
    }

    // MARK: - Running State

    func startRunning() {
        isRunning = true
    }

    func stopRunning() {
        isRunning = false
    }
}
