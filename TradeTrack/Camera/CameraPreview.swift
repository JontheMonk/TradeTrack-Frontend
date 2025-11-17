import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> Preview { Preview() }

    func updateUIView(_ uiView: Preview, context: Context) {
        uiView.videoPreviewLayer.session = session
    }

    final class Preview: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        override init(frame: CGRect) {
            super.init(frame: frame)
            isAccessibilityElement = true
            accessibilityIdentifier = "cameraPreview"
            videoPreviewLayer.videoGravity = .resizeAspectFill
        }
        required init?(coder: NSCoder) { fatalError() }
    }
}
