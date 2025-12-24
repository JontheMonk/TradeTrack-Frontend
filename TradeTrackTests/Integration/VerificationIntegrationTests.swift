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
    
    private func makeSystemUnderTest(videoName: String, employeeId: String = "EMP-123") -> (VerificationViewModel, VideoFileCameraManager) {
        guard let url = Bundle.tradeTrackCore.url(forResource: videoName, withExtension: "MOV") else {
            fatalError("❌ Test video fixture '\(videoName).MOV' not found in TradeTrackCore.")
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
        
        videoCamera.onFrameCaptured = { [weak vm] frame in
            vm?.injectTestFrame(frame)
        }
        
        return (vm, videoCamera)
    }

    // MARK: - Tests

    func testSuccessfulMatchFlow() async throws {
        let (vm, _) = makeSystemUnderTest(videoName: "happy_path_face")
        
        await vm.start()
        
        try await waitUntil(timeout: 10.0) {
            if case .matched = vm.state { return true }
            return false
        }
        
        XCTAssertEqual(vm.collectionProgress, 0.0)
        if case .matched(let name) = vm.state {
            XCTAssertEqual(name, "EMP-123")
        } else {
            XCTFail("Expected state to be .matched")
        }
    }

    func testIncorrectFaceFailure() async throws {
        let (vm, _) = makeSystemUnderTest(videoName: "wrong_employee_face")
        
        await vm.start()
        
        try await waitUntil(timeout: 5.0) { vm.collectionProgress > 0.1 }
        
        try await waitUntil(timeout: 10.0) {
            if case .detecting = vm.state { return true }
            return false
        }
    }

    func testNoFaceDetected() async throws {
        let (vm, _) = makeSystemUnderTest(videoName: "empty_background")
        
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
        // Add @escaping here
        condition: @escaping @MainActor @Sendable () -> Bool
    ) async throws {
        let start = Date()
        while true {
            // Now MainActor.run can safely "capture" the condition closure
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
