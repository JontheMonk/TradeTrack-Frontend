import Testing
import Foundation
import CoreImage
import Vision
@testable import TradeTrack
@testable import TradeTrackCore

// MARK: - Test Probe Extension
extension VerificationViewModel {
    /// Bridges the test video frames directly into the production logic.
    /// This bypasses AVFoundation hardware while exercising the real Gatekeeper and Actors.
    func injectTestFrame(_ frame: CIImage) {
        self.processInputFrame(frame)
    }
}

@MainActor
struct VerificationIntegrationTests {
    
    // MARK: - Setup Helper
    
    private func makeSystemUnderTest(videoName: String, employeeId: String = "EMP-123") -> (VerificationViewModel, VideoFileCameraManager) {
        // Use the specific bundle where your fixtures are stored
        guard let url = Bundle.tradeTrackCore.url(forResource: videoName, withExtension: "MOV") else {
            fatalError("❌ Test video fixture '\(videoName).mp4' not found in TradeTrackCore.")
        }
        
        let videoCamera = VideoFileCameraManager(videoURL: url)
        
        let vm = VerificationViewModel(
            camera: videoCamera,
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: FaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: MockFaceVerificationService(),
            errorManager: MockErrorManager(),
            employeeId: employeeId
        )
        
        // Direct bridge for the frame pipeline
        videoCamera.onFrameCaptured = { [weak vm] frame in
            vm?.injectTestFrame(frame)
        }
        
        return (vm, videoCamera)
    }

    // MARK: - Tests

    @Test("Successful match using high-quality video")
    func testSuccessfulMatchFlow() async throws {
        let (vm, _) = makeSystemUnderTest(videoName: "happy_path_face")
        
        await vm.start()
        
        // Wait for the actors to process enough frames to reach the .matched state
        try await waitUntil(timeout: 10.0) {
            if case .matched = vm.state { return true }
            return false
        }
        
        #expect(vm.collectionProgress == 0.0)
        if case .matched(let name) = vm.state {
            #expect(name == "EMP-123")
        }
    }

    @Test("Progress increases but match fails with incorrect face")
    func testIncorrectFaceFailure() async throws {
        let (vm, _) = makeSystemUnderTest(videoName: "wrong_employee_face")
        
        await vm.start()
        
        // 1. Verify that the collector is actually working and progress moves
        try await waitUntil(timeout: 5.0) { vm.collectionProgress > 0.1 }
        
        // 2. Wait for the pipeline to finish and reset to detecting (or error state)
        try await waitUntil(timeout: 10.0) {
            if case .detecting = vm.state { return true }
            return false
        }
    }

    @Test("System stays in detecting state when no face is present")
    func testNoFaceDetected() async throws {
        let (vm, _) = makeSystemUnderTest(videoName: "empty_background")
        
        await vm.start()
        
        // Run for a fixed duration to ensure no false positives
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        #expect(vm.state == .detecting)
        #expect(vm.collectionProgress == 0.0)
    }
}

// MARK: - Async Testing Helper
extension VerificationIntegrationTests {
    /// A robust polling helper that checks a condition on the MainActor.
    /// Essential for testing async pipelines where we don't know exactly
    /// which frame will trigger the state change.
    func waitUntil(
        timeout: TimeInterval,
        interval: UInt64 = 100_000_000,
        condition: @MainActor @Sendable () -> Bool
    ) async throws {
        let start = Date()
        
        // Use a loop to poll the condition
        while true {
            // Check the condition on the MainActor
            let isSatisfied = await MainActor.run { condition() }
            
            if isSatisfied { return }
            
            // Check for timeout
            if Date().timeIntervalSince(start) > timeout {
                throw AppError(code: .requestTimedOut)
            }
            
            // Wait before polling again
            try await Task.sleep(nanoseconds: interval)
        }
    }
}
