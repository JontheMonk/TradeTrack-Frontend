import Vision
import CoreImage

public protocol FaceCollecting: Sendable {
    func process(face: VNFaceObservation, image: CIImage, quality: Float) async -> (winner: (VNFaceObservation, CIImage)?, progress: Double)
    func reset() async
    
    var startTime: Date? { get async }
}
