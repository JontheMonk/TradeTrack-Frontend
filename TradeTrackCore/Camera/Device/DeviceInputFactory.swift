//
//  DeviceInputFactory.swift
//
//  Factory abstraction for creating `AVCaptureDeviceInput` wrappers.
//  Allows the camera pipeline to construct capture inputs in a controlled,
//  testable way without directly depending on AVFoundation initializers.
//
//  In production, the factory returns real `AVCaptureDeviceInput` instances.
//  In tests, a mock factory can return lightweight stub inputs or simulate
//  input-creation failures.
//

import AVFoundation

/// A factory capable of creating capture-device inputs from a given device.
///
/// `AVCaptureDeviceInput` cannot be directly instantiated in unit tests without
/// real hardware, and its initializer can throw AVFoundation errors that are
/// difficult to reproduce deterministically.
///
/// By abstracting input creation behind `DeviceInputFactory`, you can:
///
/// - inject a mock implementation in tests
/// - simulate failures (e.g., denied permissions, unsupported formats)
/// - avoid hard-dependencies on AVFoundation at call sites
/// - keep `CameraManager` small and testable
///
/// The factory produces objects conforming to `CaptureDeviceInputProtocol`,
/// which wraps the minimal interface your app needs.
protocol DeviceInputFactory {

    /// Creates a new capture-device input for the given device.
    ///
    /// This mirrors `AVCaptureDeviceInput(device:)` but returns the protocol
    /// type used throughout the camera pipeline.
    ///
    /// - Parameter device: A device conforming to `CaptureDeviceProtocol`.
    /// - Returns: A capture-device input wrapping the device.
    /// - Throws: An error if the system rejects input creation (e.g. the device
    ///   does not support video, permissions are missing, or AVFoundation fails).
    func makeInput(for device: CaptureDeviceProtocol) throws -> CaptureDeviceInputProtocol
}
