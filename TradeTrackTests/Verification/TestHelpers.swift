import Vision
import CoreImage
@testable import TradeTrack

extension VerificationViewModel {

    /// Forces the processing of a frame and waits for the ENTIRE
    /// chain (Analysis + Verification) to finish.
    func _test_runFrame(_ image: CIImage) async {
        let pipelineTask = processInputFrame(image)
        
        // If the gate was already closed, there is no new work to wait for.
        guard let pipelineTask else { return }
        
        await pipelineTask.value
        
        // Safety check: ensure the verification task actually started
        // before we try to await it.
        if let verificationTask = self.task {
            _ = await verificationTask.result
        }
    }

    /// Helper for specific assertions in your test file
    var _test_isGateClosed: Bool {
        isProcessingFrame.load(ordering: .relaxed)
    }

}
