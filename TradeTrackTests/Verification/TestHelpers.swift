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
    
    /// Helper to bridge the Atomic gate state to tests
    var _test_isGateClosed: Bool {
        isProcessingFrame.load(ordering: .relaxed)
    }

    /// Waits for the async verification task (Network/Inference) to complete.
    func _test_waitForTask() async {
        _ = await self.task?.result
    }
    
    var _test_task: Task<Void, Never>? { self.task }
}
