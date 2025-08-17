import CoreImage
import AVFoundation

/// Invariant: `image` is already oriented to `.up` (including mirroring if needed).
struct FrameInput {
    let buffer: CVPixelBuffer
    let image: CIImage
    let timestamp: CMTime
}
