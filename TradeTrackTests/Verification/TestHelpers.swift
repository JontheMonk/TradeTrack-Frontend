import Vision
import CoreImage
@testable import TradeTrack

extension VerificationViewModel {

    /// Forces the processing of a frame and waits for the ENTIRE
    /// chain (Analysis + Verification) to finish.
    func _test_runFrame(_ image: CIImage) async {
        // 1. Capture the Pipeline Task (The "Guard & Analysis" phase)
        let pipelineTask = processInputFrame(image)
        
        // 2. Wait for the analysis/collection to finish.
        // This ensures runVerificationTask() has been called.
        await pipelineTask?.value
        
        // 3. Now that Task A is done, Task B (verification) is
        // guaranteed to be assigned to the 'task' variable.
        _ = await self.task?.result
        
        // 4. Final yield to let @Published updates settle on the Main Thread
        await Task.yield()
    }

    /// Helper for specific assertions in your test file
    var _test_isGateClosed: Bool {
        isProcessingFrame.load(ordering: .relaxed)
    }

}
