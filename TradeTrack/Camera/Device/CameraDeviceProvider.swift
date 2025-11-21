//
//  CameraDeviceProvider.swift
//
//  Abstraction over `AVCaptureDevice` and related authorization APIs.
//  Allows camera access, permission checks, and default device lookup to be
//  mocked in unit tests instead of hitting real hardware or system dialogs.
//

import AVFoundation

/// A testable interface for discovering and authorizing access to camera devices.
///
/// Components like `CameraManager` depend on this protocol instead of directly
/// calling `AVCaptureDevice.default`, `authorizationStatus`, or `requestAccess`.
///
/// This enables:
/// - deterministic behavior in unit tests (no real cameras required)
/// - mocking authorization flows without triggering system permission prompts
/// - injecting alternate device sources if needed (e.g., simulator stubs)
///
/// The protocol mirrors the subset of `AVCaptureDevice` and system authorization
/// APIs actually used by the app.
protocol CameraDeviceProvider {

    /// Returns the system's default capture device matching the given criteria.
    ///
    /// This corresponds to `AVCaptureDevice.default(_:mediaType:position:)`.
    ///
    /// - Parameters:
    ///   - deviceType: The type of device to request, such as `.builtInWideAngleCamera`.
    ///   - mediaType: The AVFoundation media type, e.g. `.video`.
    ///   - position: The physical camera position, such as `.front` or `.back`.
    ///
    /// - Returns: A `CaptureDeviceProtocol` wrapping the underlying
    ///   `AVCaptureDevice`, or `nil` if no matching device is available.
    func defaultDevice(
        for deviceType: AVCaptureDevice.DeviceType,
        mediaType: AVMediaType?,
        position: AVCaptureDevice.Position
    ) -> CaptureDeviceProtocol?

    /// Returns the current authorization status for the given media type.
    ///
    /// This mirrors `AVCaptureDevice.authorizationStatus(for:)` and is used by
    /// `CameraManager` to determine whether the app can access the camera or
    /// must request permission first.
    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus

    /// Requests camera permission from the system.
    ///
    /// This wraps `AVCaptureDevice.requestAccess(for:completionHandler:)`.
    ///
    /// - Parameters:
    ///   - mediaType: Typically `.video`.
    ///   - completionHandler: Called with `true` if the user grants access,
    ///     `false` otherwise.
    ///
    /// By abstracting this call, tests can simulate permission results without
    /// triggering real authorization alerts.
    func requestAccess(
        for mediaType: AVMediaType,
        completionHandler: @escaping (Bool) -> Void
    )
}
