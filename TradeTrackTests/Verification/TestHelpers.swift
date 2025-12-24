import Vision
import CoreImage
@testable import TradeTrack

extension VerificationViewModel {
    func _test_runFrame(_ image: CIImage) async {
        await _test_handle(image)
        await _test_waitForTask()
    }

    func _test_handle(_ image: CIImage) async {
        if let (face, quality) = await self.analyzer.analyze(in: image) {
            let result = await self.collector.process(face: face, image: image, quality: quality)
            if let winner = result.winner {
                self.runVerificationTask(face: winner.0, image: winner.1)
            }
            self.collectionProgress = result.progress
        } else {
            await self.handleNoFaceDetected()
        }
    }

    /// Forces the collector to pick the current best frame immediately, bypassing the 0.8s timer.
    func _test_forceCommit() async {
        // Accessing actor state for testing
        if let winner = await collector.currentBest {
            self.runVerificationTask(face: winner.0, image: winner.1)
            await collector.reset()
        }
    }
    
    /// Helper to bridge the Atomic gate state to tests
    var _test_isGateClosed: Bool {
        isProcessingFrame.load(ordering: .relaxed)
    }

    /// Waits for the async verification task (Network/Inference) to complete.
    func _test_waitForTask() async {
        _ = await self.task?.result
    }
    
    var _test_task: Task<Void, Never>? { self.task }
    
    /// Returns the start time from the collector actor
    func getCollectionStartTime() async -> Date? {
        await collector.startTime
    }
}
