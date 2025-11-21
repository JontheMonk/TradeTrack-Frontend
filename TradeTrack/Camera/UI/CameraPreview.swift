//
//  CameraPreview.swift
//
//  SwiftUI wrapper around `AVCaptureVideoPreviewLayer`.
//  Displays the live camera feed inside a SwiftUI view hierarchy.
//  The preview layer is hosted in a lightweight UIView subclass so
//  AVFoundation can render frames efficiently.
//
//  This view does *not* own the AVCaptureSession; it simply presents it.
//  CameraManager (or another coordinator) is responsible for starting/stopping
//  the session.
//

import SwiftUI
import AVFoundation

/// A SwiftUI view that displays a live camera preview backed by
/// `AVCaptureVideoPreviewLayer`.
///
/// SwiftUI does not provide a native camera preview view, so this wrapper
/// bridges UIKit + AVFoundation using `UIViewRepresentable`. The preview layer
/// is configured once in `makeUIView` and updated whenever the session changes.
///
/// Usage:
/// ```swift
/// CameraPreview(session: cameraManager.session as! AVCaptureSession)
///     .frame(width: 300, height: 300)
/// ```
///
/// This view:
/// - uses `.resizeAspectFill` for a natural camera look
/// - assigns an accessibility identifier for UI tests
/// - keeps the preview layer as the underlying CALayer for maximum performance
struct CameraPreview: UIViewRepresentable {

    /// The capture session whose video stream should be displayed.
    let session: AVCaptureSession

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> Preview {
        Preview()
    }

    func updateUIView(_ uiView: Preview, context: Context) {
        uiView.videoPreviewLayer.session = session
    }

    // MARK: - UIKit Hosting View

    /// A lightweight hosting view whose layer is an `AVCaptureVideoPreviewLayer`.
    final class Preview: UIView {

        /// Replaces the default CALayer with a video preview layer.
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        /// Convenience accessor for the underlying preview layer.
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)

            // Helpful for UI tests and debugging
            isAccessibilityElement = true
            accessibilityIdentifier = "cameraPreview"

            // Standard camera display behavior
            videoPreviewLayer.videoGravity = .resizeAspectFill
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
