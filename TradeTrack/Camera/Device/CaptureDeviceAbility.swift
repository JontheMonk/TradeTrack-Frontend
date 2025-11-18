import AVFoundation

protocol CaptureDeviceAbility {
    var uniqueID: String { get }
    func hasMediaType(_ mediaType: AVMediaType) -> Bool
}

extension AVCaptureDevice : CaptureDeviceAbility {}
