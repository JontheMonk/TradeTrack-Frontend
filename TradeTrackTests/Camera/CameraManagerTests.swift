import XCTest
import AVFoundation
@testable import TradeTrack

final class DummyDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {}

final class CameraManagerTests: XCTestCase {

    // MARK: - Authorization

    func test_requestAuthorization_authorized_succeeds_withoutPrompt() async throws {
        let mock = MockCameraDeviceProvider()
        mock.authorizationStatusToReturn = .authorized

        let sut = CameraManager(deviceProvider: mock)
        try await sut.requestAuthorization()

        XCTAssertEqual(mock.authorizationStatusCalls, [.video])
        XCTAssertTrue(mock.requestAccessCalls.isEmpty)
    }

    func test_requestAuthorization_notDetermined_granted_succeeds() async throws {
        let mock = MockCameraDeviceProvider()
        mock.authorizationStatusToReturn = .notDetermined
        mock.requestAccessResult = true

        let sut = CameraManager(deviceProvider: mock)
        try await sut.requestAuthorization()

        XCTAssertEqual(mock.authorizationStatusCalls, [.video])
        XCTAssertEqual(mock.requestAccessCalls, [.video])
    }

    func test_requestAuthorization_notDetermined_denied_throwsCameraNotAuthorized() async {
        let mock = MockCameraDeviceProvider()
        mock.authorizationStatusToReturn = .notDetermined
        mock.requestAccessResult = false

        let sut = CameraManager(deviceProvider: mock)
        do {
            try await sut.requestAuthorization()
            XCTFail("Expected cameraNotAuthorized")
        } catch {
            XCTAssertEqual(error.appErrorCode, .cameraNotAuthorized)
        }

        XCTAssertEqual(mock.authorizationStatusCalls, [.video])
        XCTAssertEqual(mock.requestAccessCalls, [.video])
    }

    func test_requestAuthorization_deniedOrRestricted_throws() async {
        for status in [AVAuthorizationStatus.denied, .restricted] {
            let mock = MockCameraDeviceProvider()
            mock.authorizationStatusToReturn = status

            let sut = CameraManager(deviceProvider: mock)
            do {
                try await sut.requestAuthorization()
                XCTFail("Expected throw for \(status)")
            } catch {
                XCTAssertEqual(error.appErrorCode, .cameraNotAuthorized)
            }
            XCTAssertTrue(mock.requestAccessCalls.isEmpty)
        }
    }

    // MARK: - Device selection / start()

    func test_start_whenNoFrontDevice_throwsUnavailable_andQueriesTrueDepthThenWide() async {
        let mock = MockCameraDeviceProvider()
        mock.authorizationStatusToReturn = .authorized
        mock.defaultDeviceToReturn = nil // both lookups will return nil

        let sut = CameraManager(deviceProvider: mock)
        let delegate = DummyDelegate()

        do {
            try await sut.start(delegate: delegate)
            XCTFail("Expected .cameraUnavailable")
        } catch {
            XCTAssertEqual(error.appErrorCode, .cameraUnavailable)
        }

        // Assert order and parameters of lookups
        XCTAssertEqual(mock.defaultDeviceCalls.count, 2)
        if mock.defaultDeviceCalls.count == 2 {
            let first = mock.defaultDeviceCalls[0]
            XCTAssertEqual(first.type, .builtInTrueDepthCamera)
            XCTAssertEqual(first.media, .video)
            XCTAssertEqual(first.pos, .front)

            let second = mock.defaultDeviceCalls[1]
            XCTAssertEqual(second.type, .builtInWideAngleCamera)
            XCTAssertEqual(second.media, .video)
            XCTAssertEqual(second.pos, .front)
        }
    }
}
