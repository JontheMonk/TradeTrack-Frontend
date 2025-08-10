import Vision
import CoreVideo

enum FaceGeometry {
    /// Convert Vision's normalized bbox to a pixel rect for this buffer.
    static func pixelRect(for face: VNFaceObservation, in buffer: CVPixelBuffer) -> CGRect {
        VNImageRectForNormalizedRect(
            face.boundingBox,
            Int(CVPixelBufferGetWidth(buffer)),
            Int(CVPixelBufferGetHeight(buffer))
        ).integral
    }
}
