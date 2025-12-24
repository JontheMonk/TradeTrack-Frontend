import Vision
import CoreImage
@testable import TradeTrackCore

#if DEBUG
final class MockFaceCollector: FaceCollecting, @unchecked Sendable {
    // Tracking
    var resetWasCalled = false
    var processCallCount = 0
    
    // Stubs
    var stubbedStartTime: Date?
    var stubbedResult: (winner: (VNFaceObservation, CIImage)?, progress: Double) = (nil, 0.0)
    
    /// The value to return when currentBest is accessed
    var stubbedCurrentBest: (VNFaceObservation, CIImage)?

    // Protocol Requirements
    var startTime: Date? {
        get async { stubbedStartTime }
    }

    #if DEBUG
    var currentBest: (VNFaceObservation, CIImage)? {
        get async { stubbedCurrentBest }
    }
    #endif

    func process(face: VNFaceObservation, image: CIImage, quality: Float) async -> (winner: (VNFaceObservation, CIImage)?, progress: Double) {
        processCallCount += 1
        return stubbedResult
    }

    func reset() async {
        resetWasCalled = true
        stubbedStartTime = nil
    }
}
#endif
