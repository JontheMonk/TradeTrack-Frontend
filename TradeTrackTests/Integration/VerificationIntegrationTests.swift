import XCTest
import Foundation
import CoreImage
import Vision
@testable import TradeTrack
@testable import TradeTrackCore
@testable import TradeTrackMocks

// MARK: - Test Probe Extension
extension VerificationViewModel {
    func injectTestFrame(_ frame: CIImage) {
        self.processInputFrame(frame)
    }
}

@MainActor
final class VerificationIntegrationTests: XCTestCase {
    
    // MARK: - Setup Helper
    
    private func makeSystemUnderTest(
        videoName: String,
        employee: EmployeeResult = EmployeeResult(employeeId: "test_user", name: "Test User", role: "Employee"),
        analyzer: FaceAnalyzerProtocol? = nil,
        collector: FaceCollecting? = nil,
        mockError: Error? = nil
    ) -> VerificationViewModel {
        
        guard let url = Bundle.tradeTrackMocks.url(forResource: videoName, withExtension: "MOV") else {
            fatalError("❌ Test video fixture '\(videoName).MOV' not found.")
        }
        
        let videoCamera = VideoFileCameraManager(videoURL: url)
        let verifier = MockFaceVerificationService()
        verifier.stubbedError = mockError
        
        let vm = VerificationViewModel(
            camera: videoCamera,
            analyzer: analyzer ?? CoreFactory.makeFaceAnalyzer(),
            collector: collector ?? FaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: verifier,
            errorManager: MockErrorManager(),
            navigator: VerificationNavigator(nav: MockNavigator()),
            employee: employee
        )
        
        videoCamera.onFrameCaptured = { [weak vm] frame in
            vm?.processInputFrame(frame)
        }
        
        return vm
    }
    
    private func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        guard v1.count == v2.count else { return 0 }
        return zip(v1, v2).map(*).reduce(0, +)
    }

    // MARK: - Tests

    func testSuccessfulMatchFlow() async throws {
        let employee = EmployeeResult(employeeId: "jon", name: "Jon", role: "Employee")
        let vm = makeSystemUnderTest(videoName: "jon", employee: employee)
        
        await vm.start()
        
        try await waitUntil(timeout: 10.0) {
            if case .matched = vm.state { return true }
            return false
        }
        
        XCTAssertEqual(vm.collectionProgress, 0.0)
        if case .matched(let name) = vm.state {
            XCTAssertEqual(name, "Jon")  // Now checks the name, not ID
        } else {
            XCTFail("Expected state to be .matched")
        }
        
        await vm.stop()
    }
    
    func test_vm_producesSimilarEmbeddings_inDifferentLighting() async throws {
        // 1. Arrange - Setup two VMs
        let vmBright = makeSystemUnderTest(videoName: "jon")
        let vmDim = makeSystemUnderTest(videoName: "jon_dim")
        
        // Cast the verifiers to the Mock type so we can access 'lastEmbedding'
        guard let mockBright = vmBright.verifier as? MockFaceVerificationService,
              let mockDim = vmDim.verifier as? MockFaceVerificationService else {
            XCTFail("Verifier is not a MockFaceVerificationService")
            return
        }

        // 2. Act - Run the first VM until it matches
        await vmBright.start()
        try await waitUntil(timeout: 10.0) {
            if case .matched = vmBright.state { return true }
            return false
        }
        let embeddingBright = try XCTUnwrap(mockBright.lastEmbedding)
        await vmBright.stop()

        // 3. Act - Run the second VM until it matches
        await vmDim.start()
        try await waitUntil(timeout: 10.0) {
            if case .matched = vmDim.state { return true }
            return false
        }
        let embeddingDim = try XCTUnwrap(mockDim.lastEmbedding)
        await vmDim.stop()

        let similarity = cosineSimilarity(embeddingBright.values, embeddingDim.values)
        print("Lighting Drift Cosine Similarity: \(similarity)")
        XCTAssertGreaterThan(similarity, 0.6, "Lighting changes caused the embedding to drift too far (Similarity: \(similarity))")
    }
    
    func test_vm_producesSimilarEmbeddings_withGlases() async throws {
        // 1. Arrange - Setup two VMs
        let vmBright = makeSystemUnderTest(videoName: "jon")
        let vmGlasses = makeSystemUnderTest(videoName: "jon_glasses")
        
        // Cast the verifiers to the Mock type so we can access 'lastEmbedding'
        guard let mockBright = vmBright.verifier as? MockFaceVerificationService,
              let mockGlasses = vmGlasses.verifier as? MockFaceVerificationService else {
            XCTFail("Verifier is not a MockFaceVerificationService")
            return
        }

        // 2. Act - Run the first VM until it matches
        await vmBright.start()
        try await waitUntil(timeout: 10.0) {
            if case .matched = vmBright.state { return true }
            return false
        }
        let embeddingBright = try XCTUnwrap(mockBright.lastEmbedding)
        await vmBright.stop()

        // 3. Act - Run the second VM until it matches
        await vmGlasses.start()
        try await waitUntil(timeout: 10.0) {
            if case .matched = vmGlasses.state { return true }
            return false
        }
        let embeddingGlasses = try XCTUnwrap(mockGlasses.lastEmbedding)
        await vmGlasses.stop()

        let similarity = cosineSimilarity(embeddingBright.values, embeddingGlasses.values)
        print("Glasses Cosine Similarity: \(similarity)")
        XCTAssertGreaterThan(similarity, 0.6, "Glasses caused the embedding to drift too far (Similarity: \(similarity))")
    }

    func test_vm_producesDistinctEmbeddings_forDifferentPeople() async throws {
        let vmUser = makeSystemUnderTest(videoName: "jon")
        let vmImposter = makeSystemUnderTest(videoName: "imposter")
        
        guard let mockUser = vmUser.verifier as? MockFaceVerificationService,
              let mockImposter = vmImposter.verifier as? MockFaceVerificationService else {
            XCTFail("Verifier is not a MockFaceVerificationService")
            return
        }

        await vmUser.start()
        try await waitUntil(timeout: 10.0) {
            if case .matched = vmUser.state { return true }
            return false
        }
        let embeddingUser = try XCTUnwrap(mockUser.lastEmbedding)
        await vmUser.stop()

        await vmImposter.start()
        
        try await waitUntil(timeout: 10.0) {
            if case .matched = vmImposter.state { return true }
            return false
        }
        let embeddingImposter = try XCTUnwrap(mockImposter.lastEmbedding)
        await vmImposter.stop()

        let similarity = cosineSimilarity(embeddingUser.values, embeddingImposter.values)
        print("Inter-person Cosine Similarity: \(similarity)")
        XCTAssertLessThan(
            similarity,
            0.4,
            "The model is producing embeddings that are too similar for different people (Similarity: \(similarity))"
        )
    }
    
    func test_driveByVideo_shouldBeRejectedForLowQuality() async throws {
        let spyAnalyzer = MockFaceAnalyzer()
        
        let vm = makeSystemUnderTest(videoName: "driveby", analyzer: spyAnalyzer)
        
        // 2. Act
        await vm.start()
        
        // Poll the state for up to 5 seconds to let the video play
        let testTimeout = ContinuousClock().now + .seconds(5)
        
        while ContinuousClock().now < testTimeout {
            // If the state ever hits .matched, the security test fails
            if case .matched = vm.state {
                XCTFail("Security Failure: System matched on a high-speed, blurry face.")
                break
            }
            
            // Short-circuit: if the video reaches a certain frame count, we can stop early
            if spyAnalyzer.callCount >= 30 { break }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms polling
        }

        // 3. Assert
        
        // Verify Security: We stayed in the detecting state
        XCTAssertEqual(vm.state, .detecting, "VM should remain in detecting state for blurry video.")
        
        // Verify Throughput: The gate actually let frames through
        XCTAssertGreaterThan(spyAnalyzer.callCount, 0, "The analyzer should have been hit multiple times.")
        
        // Verify Reset Logic: Progress should be exactly 0.0
        XCTAssertEqual(vm.collectionProgress, 0.0, "Progress should reset to zero when faces are low quality.")
        
        // Verify Hardware Gate: Ensure the gate is OPEN and ready for the next user
        let isLocked = vm.isProcessingFrame.load(ordering: .relaxed)
        XCTAssertFalse(isLocked, "The hardware gate should be open after processing fails.")
        
        await vm.stop()
    }
    
    func test_vm_concurrency_underHighFrequencyFlood() async throws {
        // 1. Arrange
        let vm = makeSystemUnderTest(videoName: "jon")
        let frameCount = 2000
        let testFrame = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        // 2. Act: Flood the VM with frames without any delay
        // This simulates a sensor glitching or a super-high FPS camera
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<frameCount {
            vm.processInputFrame(testFrame)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // 3. Assert
        // Verify that even with 2000 frames, we didn't crash and the gate held
        XCTAssertLessThan(duration, 0.5, "The gate logic is too slow; it took too long to drop frames.")
        
        // Ensure that even after the flood, the VM is still responsive
        XCTAssertEqual(vm.state, .detecting)
        
        // Cleanup
        await vm.stop()
    }
    
}

// MARK: - Async Testing Helper
extension XCTestCase {
    func waitUntil(
        timeout: TimeInterval,
        interval: UInt64 = 100_000_000,
        condition: @escaping @MainActor @Sendable () -> Bool
    ) async throws {
        let start = Date()
        while true {
            let isSatisfied = await MainActor.run { condition() }
            
            if isSatisfied { return }
            
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("WaitUntil timed out after \(timeout)s")
                throw AppError(code: .requestTimedOut)
            }
            
            try await Task.sleep(nanoseconds: interval)
        }
    }
}
