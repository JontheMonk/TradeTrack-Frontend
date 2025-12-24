import Vision
import CoreImage

/// An actor that manages face collection safely across multiple threads.
actor FaceCollector {
    private let window: TimeInterval = 0.8
    private let highWaterMark: Float = 0.9
    
    private(set) var startTime: Date?
    private(set) var bestCandidate: (observation: VNFaceObservation, image: CIImage, quality: Float)?
    
    /// Processes a frame. This can now be safely called from any thread.
    func process(face: VNFaceObservation, image: CIImage, quality: Float) -> (winner: (VNFaceObservation, CIImage)?, progress: Double) {
        if startTime == nil { startTime = Date() }
        
        if quality > (bestCandidate?.quality ?? -1.0) {
            bestCandidate = (face, image, quality)
        }
        
        let elapsed = Date().timeIntervalSince(startTime!)
        let currentProgress = min(elapsed / window, 1.0)
        
        if elapsed >= window || quality >= highWaterMark {
            guard let winner = bestCandidate else { return (nil, currentProgress) }
            let result = (winner.observation, winner.image)
            reset()
            return (result, 1.0) // Winner found, progress is 100%
        }
        
        return (nil, currentProgress)
    }
    
    func reset() {
        startTime = nil
        bestCandidate = nil
    }
    
    
    #if DEBUG
    /// Helper for testing forced commits.
    var currentBest: (VNFaceObservation, CIImage)? {
        guard let candidate = bestCandidate else { return nil }
        return (candidate.observation, candidate.image)
    }
    #endif
}
