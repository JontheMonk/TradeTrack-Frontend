//
//  CaptureDeviceProtocol.swift
//
//  Lightweight abstraction over `AVCaptureDevice`.
//  Allows camera-related components (CameraManager, DeviceInputFactory, etc.)
//  to interact with capture devices in a testable, dependency-injected way.
//  The real `AVCaptureDevice` conforms via extension, and tests can supply mocks.
//

import AVFoundation

/// A minimal interface that represents a capture device, such as a camera.
///
/// This protocol exists so the camera pipeline does not depend directly on
/// `AVCaptureDevice`, which is difficult to mock and requires actual hardware.
/// By using `CaptureDeviceProtocol`, the app can:
///
/// - provide mock devices in unit tests
/// - decouple business logic from AVFoundation
/// - allow alternative device implementations if needed
///
/// In production, `AVCaptureDevice` conforms via an extension.
protocol CaptureDeviceProtocol {

    /// A stable identifier for the device.
    ///
    /// Mirrors `AVCaptureDevice.uniqueID`. Useful for comparing or caching
    /// devices without relying on object identity.
    var uniqueID: String { get }

    /// Returns whether the device supports a specific media type.
    ///
    /// This corresponds to `AVCaptureDevice.hasMediaType(_:)` on the real
    /// device type. Used to ensure that a device actually supports video
    /// before attempting to create inputs for it.
    ///
    /// - Parameter mediaType: The media type to check (e.g. `.video`).
    /// - Returns: `true` if the device supports the given media type.
    func hasMediaType(_ mediaType: AVMediaType) -> Bool
}

/// Conformance for the real AVFoundation capture device.
/// This allows it to be used anywhere a `CaptureDeviceProtocol` is expected.
extension AVCaptureDevice: CaptureDeviceProtocol {}
