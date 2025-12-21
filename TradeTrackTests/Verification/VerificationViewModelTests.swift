//
//  VerificationViewModelTests.swift
//  TradeTrackTests
//

import XCTest
import Vision
import CoreImage
@testable import TradeTrackCore
@testable import TradeTrack

@MainActor
final class VerificationViewModelTests: XCTestCase {

    private var mockCamera: MockCameraManager!
    private var mockAnalyzer: MockFaceAnalyzer!
    private var mockProcessor: MockFaceProcessor!
    private var mockVerifier: MockFaceVerificationService!
    private var mockError: MockErrorManager!
    private var vm: VerificationViewModel!

    private let dummyImage = CIImage(color: .red)
        .cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200))

    override func setUp() async throws {
        mockCamera = MockCameraManager()
        mockAnalyzer = MockFaceAnalyzer()
        mockProcessor = MockFaceProcessor()
        mockVerifier = MockFaceVerificationService()
        mockError = MockErrorManager()

        vm = VerificationViewModel(
            camera: mockCamera,
            analyzer: mockAnalyzer,
            processor: mockProcessor,
            verifier: mockVerifier,
            errorManager: mockError,
            employeeId: "123"
        )
    }

    // MARK: - Helpers

    private func makeFace() -> VNFaceObservation {
        VNFaceObservation(
            boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        )
    }

    // MARK: - Tests

    func test_successfulVerificationPipeline_immediateOnHighQuality() async {
        // Given: Quality is 1.0 (>= 0.9 high-water mark), bypassing the window
        mockAnalyzer.stubbedFace = makeFace()
        mockAnalyzer.stubbedQuality = 1.0

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .matched(name: "123"))
        XCTAssertEqual(mockProcessor.callCount, 1)
        XCTAssertEqual(mockVerifier.callCount, 1)
        XCTAssertNil(mockError.lastError)
    }

    func test_noFaceDetected_resetsCollection() async {
        // Given: Analyzer returns nil
        mockAnalyzer.stubbedFace = nil

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertEqual(vm.collectionProgress, 0.0)
        XCTAssertEqual(mockProcessor.callCount, 0)
    }

    func test_collectsBestFaceInWindow_thenProcesses() async {
        // 1. Send mediocre face (0.5). Should start window but not process.
        mockAnalyzer.stubbedFace = makeFace()
        mockAnalyzer.stubbedQuality = 0.5
        await vm._test_handle(dummyImage)
        
        XCTAssertEqual(mockProcessor.callCount, 0, "Should not process immediately at 0.5 quality")
        
        // 2. Send better face (0.8) during same window
        mockAnalyzer.stubbedQuality = 0.8
        await vm._test_handle(dummyImage)

        // 3. Force commit (simulating 0.8s passing)
        vm._test_forceCommit()
        await vm._test_waitForTask()

        // Then
        XCTAssertEqual(mockProcessor.callCount, 1)
        XCTAssertEqual(vm.state, .matched(name: "123"))
    }

    func test_processorThrows_surfacesErrorAndResetsState() async {
        // Given
        mockAnalyzer.stubbedFace = makeFace()
        mockAnalyzer.stubbedQuality = 1.0
        mockProcessor.stubbedError = AppError(code: .modelOutputMissing)

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertEqual(mockError.lastError?.code, .modelOutputMissing)
    }

    func test_verifierThrows_surfacesErrorAndResetsState() async {
        // Given
        mockAnalyzer.stubbedFace = makeFace()
        mockAnalyzer.stubbedQuality = 1.0
        mockVerifier.stubbedError = AppError(code: .networkUnavailable)

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertEqual(mockVerifier.callCount, 1)
        XCTAssertEqual(mockError.lastError?.code, .networkUnavailable)
    }

    func test_throttling_ignoresFramesWhileTaskIsActive() async {
        // Given
        mockAnalyzer.stubbedFace = makeFace()
        mockAnalyzer.stubbedQuality = 1.0

        // Start first frame/task
        await vm._test_handle(dummyImage)
        
        // Immediately send another frame while first is still "processing"
        await vm._test_handle(dummyImage)
        
        // Wait for whatever started to finish
        await vm._test_waitForTask()

        // Then
        XCTAssertEqual(mockProcessor.callCount, 1, "The second frame should have been ignored due to active task")
    }

    func test_stop_cancelsInFlightTask() async {
        mockAnalyzer.stubbedFace = makeFace()
        mockAnalyzer.stubbedQuality = 1.0

        // Kick off handle but don't wait for completion
        await vm._test_handle(dummyImage)

        // Stop immediately
        await vm.stop()

        // Then
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertNil(vm._test_task, "Task should be cleared")
    }

    func test_missingEmployeeID_failsEarly() async {
        // Given
        vm.targetEmployeeID = nil
        mockAnalyzer.stubbedFace = makeFace()
        mockAnalyzer.stubbedQuality = 1.0

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(mockError.lastError?.code, .employeeNotFound)
        XCTAssertEqual(vm.state, .detecting)
    }
}
