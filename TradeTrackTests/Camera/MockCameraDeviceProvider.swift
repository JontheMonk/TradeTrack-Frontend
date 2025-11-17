import AVFoundation
@testable import TradeTrack
import XCTest

final class MockCameraDeviceProvider: CameraDeviceProvider {

    var defaultDeviceToReturn: AVCaptureDevice? = nil
    var authorizationStatusToReturn: AVAuthorizationStatus = .notDetermined
    var requestAccessResult: Bool = false

    // Spies to assert usage
    private(set) var defaultDeviceCalls: [(type: AVCaptureDevice.DeviceType, media: AVMediaType?, pos: AVCaptureDevice.Position)] = []
    private(set) var authorizationStatusCalls: [AVMediaType] = []
    private(set) var requestAccessCalls: [AVMediaType] = []

    func defaultDevice(for deviceType: AVCaptureDevice.DeviceType,
                       mediaType: AVMediaType?,
                       position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        defaultDeviceCalls.append((deviceType, mediaType, position))
        return defaultDeviceToReturn
    }

    func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        authorizationStatusCalls.append(mediaType)
        return authorizationStatusToReturn
    }

    func requestAccess(for mediaType: AVMediaType, completionHandler: @escaping (Bool) -> Void) {
        requestAccessCalls.append(mediaType)
        completionHandler(requestAccessResult)
    }
}

