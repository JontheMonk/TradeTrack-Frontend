import AVFoundation
import CoreImage
import TradeTrackCore

/// A CameraManager that simulates a live feed by reading frames from a video file.
/// Isolated to @MainActor to safely coordinate with the VerificationViewModel and UI.
@MainActor
final class VideoFileCameraManager: CameraManagerProtocol {
    
    // MARK: - CameraManagerProtocol Requirements
    
    /// Returns a dummy session for protocol compliance.
    let session: CaptureSessionProtocol = MockCaptureSession()
    
    var uiCaptureSession: AVCaptureSession {
        return session.uiSession
    }

    // MARK: - Video Playback Properties
    
    private let videoURL: URL
    private var isPlaying = false
    
    /// A closure that allows the test suite to bridge captured frames to the ViewModel.
    var onFrameCaptured: ((CIImage) -> Void)?
    
    init(videoURL: URL) {
        self.videoURL = videoURL
    }

    func requestAuthorization() async throws {
        // Biometric playback from local files is always authorized in this mock.
    }

    func start<D>(delegate: D) async throws where D : AVCaptureVideoDataOutputSampleBufferDelegate & Sendable {
        guard !isPlaying else { return }
        isPlaying = true
        
        startFrameExtraction(delegate: delegate)
    }

    func stop() async {
        isPlaying = false
    }

    // MARK: - Frame Extraction Engine

    /// Reads frames at a fixed 30fps rate using an async loop.
    private func startFrameExtraction<D: AVCaptureVideoDataOutputSampleBufferDelegate>(delegate: D) {
        Task {
            let asset = AVURLAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            generator.appliesPreferredTrackTransform = true

            guard let duration = try? await asset.load(.duration).seconds else { return }
            
            var currentTime: Double = 0
            let frameStep: Double = 1.0 / 30.0

            while isPlaying {
                let time = CMTime(seconds: currentTime, preferredTimescale: 600)
                
                if let (cgImage, _) = try? await generator.image(at: time) {
                    let ciImage = CIImage(cgImage: cgImage)
                    self.deliver(ciImage)
                }
                
                currentTime += frameStep
                if currentTime >= duration {
                    currentTime = 0 // Loop the video
                }
                
                // Control frame rate
                try? await Task.sleep(nanoseconds: UInt64(frameStep * 1_000_000_000))
            }
        }
    }
    
    private func deliver(_ image: CIImage) {
        self.onFrameCaptured?(image)
    }
}
