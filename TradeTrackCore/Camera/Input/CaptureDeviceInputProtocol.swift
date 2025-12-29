//
//  CaptureDeviceInputProtocol.swift
//
//  Abstraction over `AVCaptureDeviceInput`. Used so the camera pipeline can
//  depend on a lightweight, testable interface instead of the AVFoundation
//  concrete type, which cannot be instantiated with mock devices.
//
//  `AVCaptureDeviceInput` conforms via an extension, and tests can supply their
//  own mock inputs.
//

import AVFoundation

/// A minimal interface representing a capture-session input.
///
/// This protocol wraps the portion of `AVCaptureDeviceInput` that the app
/// actually uses—specifically, access to the underlying device. By depending on
/// `CaptureDeviceInputProtocol` instead of the concrete `AVCaptureDeviceInput`,
/// components such as `CameraManager` become easier to mock and unit test.
///
/// In production:
/// - The real `AVCaptureDeviceInput` conforms via an extension.
///
/// In tests:
/// - Mock implementations can supply fake devices and avoid touching hardware.
public protocol CaptureDeviceInputProtocol: AnyObject {

    /// The `CaptureDeviceProtocol` backing this input.
    ///
    /// In the production implementation, this simply exposes the underlying
    /// `AVCaptureDevice`. Mock implementations can provide any behavior needed
    /// for testing without requiring real camera hardware.
    var captureDevice: CaptureDeviceProtocol { get }
}

/// Real `AVCaptureDeviceInput` conformance.
/// This enables it to be used anywhere a `CaptureDeviceInputProtocol` is expected.
extension AVCaptureDeviceInput: CaptureDeviceInputProtocol {
    public var captureDevice: CaptureDeviceProtocol { self.device }
}
