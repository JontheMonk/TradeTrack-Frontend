//
//  RealDeviceInputCreator.swift
//
//  Concrete implementation of `DeviceInputFactory` that constructs real
//  `AVCaptureDeviceInput` objects from AVFoundation. This is the production
//  path used by `CameraManager` to attach camera devices to a capture session.
//
//  Tests provide a mock `DeviceInputFactory` instead, allowing the camera
//  pipeline to simulate input creation without requiring actual hardware.
//

import AVFoundation

/// Production factory that creates real `AVCaptureDeviceInput` instances.
///
/// The camera pipeline interacts only with `DeviceInputFactory` and
/// `CaptureDeviceInputProtocol`, so this concrete type acts as the bridge to
/// AVFoundation. It converts the abstract `CaptureDeviceProtocol` back into
/// the underlying `AVCaptureDevice` and performs the actual input creation.
///
/// ### Important
/// This factory assumes the caller passes a real `AVCaptureDevice`
/// (i.e., the production provider). Passing a mock device is a programmer
/// error and results in an immediate `fatalError`, since a mock device cannot
/// be wrapped by `AVCaptureDeviceInput`.
///
/// In tests, use a `MockDeviceInputFactory` that returns mock inputs instead of
/// invoking this real implementation.
final class RealDeviceInputCreator: DeviceInputFactory {

    /// Creates a real `AVCaptureDeviceInput` for the given device.
    ///
    /// - Parameter device: A `CaptureDeviceProtocol` expected to be an
    ///   `AVCaptureDevice` at runtime.
    /// - Returns: A concrete `CaptureDeviceInputProtocol` wrapping
    ///   `AVCaptureDeviceInput`.
    /// - Throws: Any error thrown by `AVCaptureDeviceInput(device:)`,
    ///   such as when the device is unavailable or unsupported.
    ///
    /// - Note:
    ///   If a mock or non-AVFoundation device is passed, this method triggers
    ///   a `fatalError`. Production code should always supply a real device.
    func makeInput(for device: CaptureDeviceProtocol) throws -> CaptureDeviceInputProtocol {

        guard let avDevice = device as? AVCaptureDevice else {
            fatalError("RealDeviceInputCreator expects real AVCaptureDevice")
        }

        let input = try AVCaptureDeviceInput(device: avDevice)
        return input
    }
}
