import AVFoundation
@testable import TradeTrackCore

/// A test double for `DeviceInputFactory`.
///
/// This mock allows tests to control:
///   - **Which input object** will be returned (`nextInput`)
///   - **Whether an error should be thrown** (`errorToThrow`)
///   - **Which device was requested** (`lastRequestedDevice`)
///
/// Why this exists:
/// ----------------
/// `AVCaptureDeviceInput` cannot be instantiated in tests (it touches hardware
/// and requires real devices).
/// `CameraManager` depends on a factory to create such inputs, so this mock
/// provides deterministic, controllable behavior.
///
/// Usage pattern in tests:
/// ------------------------
/// ```swift
/// let creator = MockDeviceInputCreator()
/// creator.nextInput = MockCaptureDeviceInput(device: someDevice)
///
/// let sut = CameraManager(inputCreator: creator, ...)
/// try await sut.start(delegate: ...)
///
/// XCTAssertEqual(creator.lastRequestedDevice?.uniqueID, someDevice.uniqueID)
/// ```
///
/// If `errorToThrow` is set, the factory simulates a construction failure,
/// allowing tests to ensure `CameraManager` correctly maps the error into
/// `.cameraInputFailed`.
final class MockDeviceInputCreator: DeviceInputFactory {

    /// The next input to return when `makeInput(for:)` is called.
    /// Must be set by the test; otherwise the mock will `fatalError()`
    /// so test authors notice misconfiguration immediately.
    var nextInput: CaptureDeviceInputProtocol?

    /// If set, `makeInput(for:)` throws this error instead of returning an input.
    /// Useful for testing failure paths.
    var errorToThrow: Error?

    /// Captures which device was passed to `makeInput(for:)` for verification.
    private(set) var lastRequestedDevice: CaptureDeviceProtocol?

    /// Simulates creation of a device input.
    ///
    /// - Parameter device: The capture device the session wants to wrap.
    /// - Returns: The mock input specified in `nextInput`.
    /// - Throws: `errorToThrow` if provided.
    func makeInput(for device: CaptureDeviceProtocol) throws -> CaptureDeviceInputProtocol {
        lastRequestedDevice = device

        if let error = errorToThrow {
            throw error
        }

        guard let input = nextInput else {
            fatalError("MockDeviceInputCreator.nextInput was not set before makeInput(for:) was called.")
        }

        return input
    }
}
