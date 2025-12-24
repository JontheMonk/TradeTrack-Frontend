import Testing
import Foundation
import CoreImage
import Vision
@testable import TradeTrack
@testable import TradeTrackCore

@MainActor
struct VerificationIntegrationTests {
    
    // MARK: - Setup Helper
    
    /// Helper to create a VM with the video-based camera manager
    private func makeSystemUnderTest(videoName: String, employeeId: String = "EMP-123") -> (VerificationViewModel, VideoFileCameraManager) {
        let bundle = Bundle(for: VerificationViewModel.self)
        guard let url = bundle.url(forResource: videoName, withExtension: "mp4") else {
            fatalError("Missing test video: \(videoName)")
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
        
        // Bridge the video camera frames to the VM delegate
        videoCamera.onFrameCaptured = { frame in
            // Simulate the bridge normally handled by VerificationOutputDelegate
            NotificationCenter.default.post(name: .didReceiveFrame, object: frame)
        }
        
        return (vm, videoCamera)
    }

    // MARK: - Tests

    @Test("Successful match using high-quality video")
    func testSuccessfulMatchFlow() async throws {
        let (vm, camera) = makeSystemUnderTest(videoName: "happy_path_face")
        
        await vm.start()
        
        // Use a Task to wait for the state change with a timeout
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
        let (vm, camera) = makeSystemUnderTest(videoName: "wrong_employee_face")
        
        await vm.start()
        
        // We expect progress to happen, but eventually show an error or reset
        try await waitUntil(timeout: 5.0) { vm.collectionProgress > 0.1 }
        
        // Wait for the final state to be detecting again after an error
        try await waitUntil(timeout: 10.0) {
            if case .detecting = vm.state { return true }
            return false
        }
    }

    @Test("System stays in detecting state when no face is present")
    func testNoFaceDetected() async throws {
        let (vm, camera) = makeSystemUnderTest(videoName: "empty_background")
        
        await vm.start()
        
        // Wait a few seconds of playback
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        #expect(vm.state == .detecting)
        #expect(vm.collectionProgress == 0.0)
    }
}

// MARK: - Async Testing Helper
extension VerificationIntegrationTests {
    func waitUntil(timeout: TimeInterval, condition: @MainActor () -> Bool) async throws {
        let start = Date()
        while await !condition() {
            if Date().timeIntervalSince(start) > timeout {
                throw AppleError(code: .timeout)
            }
            try await Task.sleep(nanoseconds: 100_000_000) // Poll every 100ms
        }
    }
}
