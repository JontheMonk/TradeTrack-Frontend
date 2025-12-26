import XCTest
import Vision
import CoreImage
@testable import TradeTrackCore
@testable import TradeTrack
@testable import TradeTrackMocks

@MainActor
final class VerificationViewModelTests: XCTestCase {

    private var mockCamera: MockCameraManager!
    private var mockAnalyzer: MockFaceAnalyzer!
    private var mockCollector: MockFaceCollector!
    private var mockProcessor: MockFaceProcessor!
    private var mockVerifier: MockFaceVerificationService!
    private var mockError: MockErrorManager!
    private var vm: VerificationViewModel!

    private let dummyImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200))

    override func setUp() async throws {
        mockCamera = MockCameraManager()
        mockAnalyzer = MockFaceAnalyzer()
        mockCollector = MockFaceCollector()
        mockProcessor = MockFaceProcessor()
        mockVerifier = MockFaceVerificationService()
        mockError = MockErrorManager()

        vm = VerificationViewModel(
            camera: mockCamera,
            analyzer: mockAnalyzer,
            collector: mockCollector,
            processor: mockProcessor,
            verifier: mockVerifier,
            errorManager: mockError,
            employeeId: "123"
        )
    }

    // MARK: - Helpers

    private func makeFace() -> VNFaceObservation {
        VNFaceObservation(boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3))
    }

    // MARK: - Tests

    func test_successfulVerificationPipeline_immediateOnHighQuality() async {
        // Given: Collector returns a winner immediately (simulating quality >= 0.9)
        let face = makeFace()
        mockAnalyzer.stubbedFace = face
        mockAnalyzer.stubbedQuality = 1.0
        mockCollector.stubbedResult = (winner: (face, dummyImage), progress: 0.0)

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .matched(name: "123"))
        XCTAssertEqual(mockProcessor.callCount, 1)
        XCTAssertEqual(mockVerifier.callCount, 1)
    }

    func test_noFaceDetected_resetsCollectorAndAnalyzer() async {
        // 1. Arrange
        mockAnalyzer.stubbedFace = nil
        mockCollector.stubbedStartTime = Date()

        // 2. Act: Catch and await the task so the logic completes
        let pipeline = vm.processInputFrame(dummyImage)
        await pipeline?.value
        await Task.yield() // Ensure resets finish

        // 3. Assert
        XCTAssertTrue(mockCollector.resetWasCalled)
        XCTAssertTrue(mockAnalyzer.resetWasCalled)
    }

    func test_verificationPhase_closesGate() async {
        // 1. Setup: We need to simulate a "Winner" being found by the collector
        // You might need to mock your collector to return a winner immediately
        
        // 2. Run the verification task directly or trigger a frame that results in a winner
        vm.runVerificationTask(face: makeFace(), image: dummyImage)
        
        // 3. NOW the gate should be closed
        XCTAssertTrue(vm.isProcessingFrame.load(ordering: .relaxed),
                      "Gate should be closed once a verification task starts")
        
        // 4. Any frame arriving now must be dropped
        let third = vm.processInputFrame(dummyImage)
        XCTAssertNil(third, "Frames must be dropped while a verification task is in flight")
    }

    func test_stop_cancelsTaskAndResetsState() async {
        // Given: A task is running
        mockAnalyzer.stubbedFace = makeFace()
        mockCollector.stubbedResult = (winner: (makeFace(), dummyImage), progress: 0.0)
        
        await vm._test_runFrame(dummyImage)
        
        // When: Stop is called
        await vm.stop()

        // Then
        XCTAssertNil(vm.task, "Task reference should be cleared")
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertTrue(mockCollector.resetWasCalled)
        XCTAssertFalse(vm._test_isGateClosed, "Gate should be reopened after stop")
    }

    func test_processorError_locksGateUntilRetry() async {
        // Given
        mockAnalyzer.stubbedFace = makeFace()
        mockCollector.stubbedResult = (winner: (makeFace(), dummyImage), progress: 0.0)
        mockProcessor.stubbedError = AppError(code: .modelOutputMissing)

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(mockError.lastError?.code, .modelOutputMissing)
        XCTAssertEqual(vm.state, .detecting)
        
        // UPDATED: The gate should now be CLOSED (True)
        XCTAssertTrue(vm.isProcessingFrame.load(ordering: .relaxed), "Gate must stay locked after processor failure")
        
        // Verify we can't process more frames
        let nextTask = vm.processInputFrame(dummyImage)
        XCTAssertNil(nextTask, "Should drop frames while locked")
    }

    func test_missingEmployeeID_failsEarly() async {
        // Given
        vm.targetEmployeeID = nil
        mockAnalyzer.stubbedFace = makeFace()
        mockCollector.stubbedResult = (winner: (makeFace(), dummyImage), progress: 0.0)

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(mockError.lastError?.code, .employeeNotFound)
        XCTAssertEqual(vm.state, .detecting)
    }

    func test_start_handlesCameraAuthorizationFailure() async {
        // Given
        mockCamera.startShouldThrow = AppError(code: .cameraNotAuthorized)

        // When
        await vm.start()

        // Then
        XCTAssertEqual(mockError.lastError?.code, .cameraNotAuthorized)
    }
    
    func test_onVerificationError_gateRemainsLocked_untilRetryIsCalled() async {
        // 1. Given: A failure scenario (e.g., employee not found)
        let expectedError = AppError(code: .employeeNotFound)
        mockAnalyzer.stubbedFace = makeFace()
        mockCollector.stubbedResult = (winner: (makeFace(), dummyImage), progress: 0.0)
        mockVerifier.stubbedError = expectedError

        // 2. When: The verification pipeline runs and fails
        await vm._test_runFrame(dummyImage)

        // 3. Then: Verify the gate is still CLOSED (Locked)
        // This is your new logic: we don't allow new frames yet.
        XCTAssertTrue(vm.isProcessingFrame.load(ordering: .relaxed),
                      "Gate should remain locked after a verification error")
        
        // 4. Verify that new frames are dropped while locked
        let droppedTask = vm.processInputFrame(dummyImage)
        XCTAssertNil(droppedTask, "New frames must be ignored while the gate is locked post-error")

        // 5. When: The user taps "Try Again"
        vm.retry()

        // 6. Then: The gate should be OPEN (Unlocked) and state reset
        XCTAssertFalse(vm.isProcessingFrame.load(ordering: .relaxed),
                       "Retry must explicitly re-open the hardware gate")
        XCTAssertEqual(vm.state, .detecting, "State should reset to detecting after retry")
        XCTAssertEqual(vm.collectionProgress, 0.0, "Progress should reset to 0 after retry")
    }
}
