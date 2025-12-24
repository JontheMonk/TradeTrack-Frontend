//
//  VerificationViewModel+Testing.swift
//

import Vision
import CoreImage
import TradeTrackCore
import Synchronization

#if DEBUG
extension VerificationViewModel {
    
    // MARK: - Helper Methods for Unit Tests
    
    /// Simulates a full camera frame cycle and waits for the resulting verification task to finish.
    func _test_runFrame(_ image: CIImage) async {
        await _test_handle(image)
        await _test_waitForTask()
    }

    /// Manually pushes an image through the pipeline, bypassing the Camera Delegate.
    func _test_handle(_ image: CIImage) async {
        // Analyzer is nonisolated, but we await the call
        if let (face, quality) = await self.analyzer.analyze(in: image) {
            
            // 1. Collector is an Actor, must await the process call
            let result = await self.collector.process(face: face, image: image, quality: quality)
            
            // 2. Back on MainActor (inherited from ViewModel), apply the result
            if let winner = result.winner {
                self.runVerificationTask(face: winner.0, image: winner.1)
            }
            
            // 3. Update progress from the actor's state
            self.collectionProgress = result.progress
        } else {
            // Reaches out to handleNoFaceDetected which handles collector reset
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

    // MARK: - UI Test Bridge
    
    func installUITestSignalBridge() {
        guard AppRuntime.mode == .uiTest else { return }
        
        let center = NotificationCenter.default
        
        let observer1 = center.addObserver(
            forName: .uiTestCameraNoFace,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.state = .detecting
            }
        }

        let observer2 = center.addObserver(
            forName: .uiTestCameraValidFace,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.state = .matched(name: "Test User")
            }
        }
        
        self.uiTestObservers.append(contentsOf: [observer1, observer2])
    }
}
#endif
