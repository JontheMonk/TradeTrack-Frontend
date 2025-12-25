import XCTest
import Foundation
import CoreImage
import Vision
@testable import TradeTrack
@testable import TradeTrackCore

// MARK: - Test Probe Extension
extension VerificationViewModel {
    func injectTestFrame(_ frame: CIImage) {
        self.processInputFrame(frame)
    }
}

@MainActor
final class VerificationIntegrationTests: XCTestCase {
    
    // MARK: - Setup Helper
    
    private func makeSystemUnderTest(videoName: String, employeeId: String = "test_user", mockError: Error? = nil) -> VerificationViewModel {
        guard let url = Bundle.tradeTrackCore.url(forResource: videoName, withExtension: "MOV") else {
            fatalError("❌ Test video fixture '\(videoName).MOV' not found in TradeTrackCore.")
        }
        
        let videoCamera = VideoFileCameraManager(videoURL: url)
        
        let verifier = MockFaceVerificationService()
        verifier.stubbedError = mockError
        
        let vm = VerificationViewModel(
            camera: videoCamera,
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: FaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: verifier,
            errorManager: MockErrorManager(),
            employeeId: employeeId
        )
        
        videoCamera.onFrameCaptured = { [weak vm] frame in
            vm?.injectTestFrame(frame)
        }
        
        return vm
    }
    
    private func calculateEuclideanDistance(_ v1: [Float], _ v2: [Float]) -> Float {
        guard v1.count == v2.count else { return .infinity }
        let sumOfSquares = zip(v1, v2).map { pow($0 - $1, 2) }.reduce(0, +)
        return sqrt(sumOfSquares)
    }

    // MARK: - Tests

    func testSuccessfulMatchFlow() async throws {
        let vm = makeSystemUnderTest(videoName: "jon", employeeId: "jon")
        
        await vm.start()
        
        try await waitUntil(timeout: 10.0) {
            if case .matched = vm.state { return true }
            return false
        }
        
        XCTAssertEqual(vm.collectionProgress, 0.0)
        if case .matched(let name) = vm.state {
            XCTAssertEqual(name, "jon")
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

        // 4. Assert - Compare the embeddings
        let distance = calculateEuclideanDistance(embeddingBright.values, embeddingDim.values)
        
        // Log the distance for easier debugging in the test report
        print("Lighting Drift Euclidean Distance: \(distance)")
        
        // Threshold check: 0.9 is a standard limit for same-person verification
        XCTAssertLessThan(distance, 0.9, "Lighting changes caused the embedding to drift too far (Distance: \(distance))")
    }

    func testIncorrectFaceFailure() async throws {
        let vm = makeSystemUnderTest(videoName: "wrong_employee_face")
        
        await vm.start()
        
        try await waitUntil(timeout: 5.0) { vm.collectionProgress > 0.1 }
        
        try await waitUntil(timeout: 10.0) {
            if case .detecting = vm.state { return true }
            return false
        }
    }

    func testNoFaceDetected() async throws {
        let vm = makeSystemUnderTest(videoName: "empty_background")
        
        await vm.start()
        
        // Wait 2 seconds
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertEqual(vm.collectionProgress, 0.0)
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
