import Vision
import CoreImage

/// An actor that manages face collection safely across multiple threads.
actor FaceCollector {
    private let window: TimeInterval = 0.8
    private let highWaterMark: Float = 0.9
    
    private(set) var startTime: Date?
    private(set) var bestCandidate: (observation: VNFaceObservation, image: CIImage, quality: Float)?
    
    /// Processes a frame. This can now be safely called from any thread.
    func process(face: VNFaceObservation, image: CIImage, quality: Float) -> (VNFaceObservation, CIImage)? {
        if startTime == nil { startTime = Date() }
        
        if quality > (bestCandidate?.quality ?? -1.0) {
            bestCandidate = (face, image, quality)
        }
        
        let elapsed = Date().timeIntervalSince(startTime!)
        
        if elapsed >= window || quality >= highWaterMark {
            guard let winner = bestCandidate else { return nil }
            let result = (winner.observation, winner.image)
            reset()
            return result
        }
        return nil
    }
    
    func reset() {
        startTime = nil
        bestCandidate = nil
    }
    
    /// Calculated progress.
    var progress: Double {
        guard let start = startTime else { return 0.0 }
        return min(Date().timeIntervalSince(start) / window, 1.0)
    }

    /// Helper for testing forced commits.
    var currentBest: (VNFaceObservation, CIImage)? {
        guard let candidate = bestCandidate else { return nil }
        return (candidate.observation, candidate.image)
    }
}
