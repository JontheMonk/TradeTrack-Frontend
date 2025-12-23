//
//  VerificationViewModel+Testing.swift
//

import Vision
import CoreImage
import TradeTrackCore

#if DEBUG
extension VerificationViewModel {
    
    // MARK: - Helper Methods for Unit Tests
    
    func _test_runFrame(_ image: CIImage) async {
        await _test_handle(image)
        await _test_waitForTask()
    }

    func _test_handle(_ image: CIImage) async {
        if let (face, quality) = self.analyzer.analyze(in: image) {
            // Await the actor call
            if let winner = await self.collector.process(face: face, image: image, quality: quality) {
                self.runVerificationTask(face: winner.0, image: winner.1)
            }
            self.collectionProgress = await self.collector.progress
        } else {
            self.handleNoFaceDetected()
        }
    }

    func _test_forceCommit() {
        Task {
            // Await the actor call
            if let winner = await collector.currentBest {
                await MainActor.run {
                    runVerificationTask(face: winner.0, image: winner.1)
                }
                await collector.reset()
            }
        }
    }
    
    func _test_waitForTask() async {
        await self.task?.value
    }
    
    var _test_task: Task<Void, Never>? { self.task }
    var _test_collectionStartTime: Date? { collector.startTime }

    // MARK: - UI Test Bridge
    
    /// This can be called from your VM's start() method
    func installUITestSignalBridge() {
        guard AppRuntime.mode == .uiTest else { return }
        
        let center = NotificationCenter.default
        center.addObserver(forName: .uiTestCameraNoFace, object: nil, queue: .main) { [weak self] _ in
            self?.state = .detecting
        }

        center.addObserver(forName: .uiTestCameraValidFace, object: nil, queue: .main) { [weak self] _ in
            self?.state = .matched(name: "Test User")
        }
    }
}
#endif
