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

    func test_successfulVerificationPipeline() async {
        // Given
        mockAnalyzer.stubbedFace = makeFace()

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .matched(name: "123"))
        XCTAssertEqual(mockProcessor.callCount, 1)
        XCTAssertEqual(mockVerifier.callCount, 1)
        XCTAssertNil(mockError.lastError)
    }

    func test_noFaceDetected_doesNothing() async {
        // Given
        mockAnalyzer.stubbedFace = nil

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertEqual(mockProcessor.callCount, 0)
        XCTAssertEqual(mockVerifier.callCount, 0)
    }

    func test_processorThrows_surfacesErrorAndResetsState() async {
        // Given
        mockAnalyzer.stubbedFace = makeFace()
        mockProcessor.stubbedError = AppError(code: .modelOutputMissing)

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertEqual(mockProcessor.callCount, 1)
        XCTAssertEqual(mockVerifier.callCount, 0)
        XCTAssertEqual(mockError.lastError?.code, .modelOutputMissing)
    }

    func test_verifierThrows_surfacesErrorAndResetsState() async {
        // Given
        mockAnalyzer.stubbedFace = makeFace()
        mockVerifier.stubbedError = AppError(code: .networkUnavailable)

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(vm.state, .detecting)
        XCTAssertEqual(mockProcessor.callCount, 1)
        XCTAssertEqual(mockVerifier.callCount, 1)
        XCTAssertEqual(mockError.lastError?.code, .networkUnavailable)
    }

    func test_throttling_allowsOnlyOneFramePerInterval() async {
        // Given
        mockAnalyzer.stubbedFace = makeFace()

        // First frame
        await vm._test_runFrame(dummyImage)
        XCTAssertEqual(mockProcessor.callCount, 1)

        // Immediately process another frame — should be throttled
        await vm._test_runFrame(dummyImage)
        XCTAssertEqual(mockProcessor.callCount, 1,
            "Second frame should be throttled and ignored"
        )
    }

    func test_cancelsTaskIfStoppedEarly() async {
        mockAnalyzer.stubbedFace = makeFace()

        // Kick off processing
        await vm._test_handle(dummyImage)   // don't wait for full pipeline yet

        // Stop the VM while task is running
        await vm.stop()

        // Then
        XCTAssertEqual(vm.state, .detecting)
    }

    func test_missingEmployeeIDThrows() async {
        // Given
        vm.targetEmployeeID = nil
        mockAnalyzer.stubbedFace = makeFace()

        // When
        await vm._test_runFrame(dummyImage)

        // Then
        XCTAssertEqual(mockError.lastError?.code, .employeeNotFound)
        XCTAssertEqual(vm.state, .detecting)
    }
}
