//
//  RealCameraDeviceProvider.swift
//
//  Concrete implementation of `CameraDeviceProvider` that forwards all calls
//  directly to `AVCaptureDevice` and the related system authorization APIs.
//
//  This is the production provider used by CameraManager. Unit tests typically
//  use a mock implementation to avoid hitting hardware or triggering permission
//  dialogs.
//

import AVFoundation

/// Production implementation of `CameraDeviceProvider` backed by AVFoundation.
///
/// This type provides the actual camera devices, authorization status, and
/// permission requests used by the app. Because it conforms to
/// `CameraDeviceProvider`, the rest of the camera pipeline (e.g. `CameraManager`)
/// does not depend directly on AVFoundation and can be fully mocked in tests.
///
/// In tests:
/// - You replace this with a `MockCameraDeviceProvider`.
/// - No real camera hardware or permission prompts are triggered.
///
/// In production:
/// - All calls simply forward to the corresponding `AVCaptureDevice` APIs.
final class RealCameraDeviceProvider: CameraDeviceProvider {

    /// Returns the system’s default capture device matching the given criteria.
    ///
    /// Direct wrapper around:
    /// `AVCaptureDevice.default(_:for:position:)`
    func defaultDevice(
        for deviceType: AVCaptureDevice.DeviceType,
        mediaType: AVMediaType?,
        position: AVCaptureDevice.Position
    ) -> CaptureDeviceProtocol? {
        AVCaptureDevice.default(deviceType, for: mediaType, position: position)
    }

    /// Returns the system authorization status for the given media type.
    ///
    /// Direct wrapper around:
    /// `AVCaptureDevice.authorizationStatus(for:)`
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: mediaType)
    }

    /// Requests camera access from the system.
    ///
    /// Direct wrapper around:
    /// `AVCaptureDevice.requestAccess(for:completionHandler:)`
    ///
    /// This call will trigger the system permission alert in production.
    /// In tests, use a mock provider to simulate user responses instead.
    func requestAccess(
        for mediaType: AVMediaType,
        completionHandler: @escaping (Bool) -> Void
    ) {
        AVCaptureDevice.requestAccess(for: mediaType, completionHandler: completionHandler)
    }
}
