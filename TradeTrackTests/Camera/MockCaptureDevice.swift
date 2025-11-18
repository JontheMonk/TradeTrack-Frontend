import AVFoundation
@testable import TradeTrack

struct MockCaptureDevice: CaptureDeviceAbility {
    let uniqueID: String
    let supportedMediaTypes: [AVMediaType]

    init(
        uniqueID: String = UUID().uuidString,
        supportedMediaTypes: [AVMediaType] = [.video]
    ) {
        self.uniqueID = uniqueID
        self.supportedMediaTypes = supportedMediaTypes
    }

    func hasMediaType(_ mediaType: AVMediaType) -> Bool {
        supportedMediaTypes.contains(mediaType)
    }
}
