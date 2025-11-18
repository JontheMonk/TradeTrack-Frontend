import XCTest
import AVFoundation
@testable import TradeTrack

final class DummyDelegate: NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {}

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

    func test_requestAuthorization_notDetermined_denied_throws() async {
        let mock = MockCameraDeviceProvider()
        mock.authorizationStatusToReturn = .notDetermined
        mock.requestAccessResult = false

        let sut = CameraManager(deviceProvider: mock)

        do {
            try await sut.requestAuthorization()
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error.appErrorCode, .cameraNotAuthorized)
        }
    }

    func test_requestAuthorization_deniedOrRestricted_throws() async {
        for status in [AVAuthorizationStatus.denied, .restricted] {
            let mock = MockCameraDeviceProvider()
            mock.authorizationStatusToReturn = status
            let sut = CameraManager(deviceProvider: mock)

            do {
                try await sut.requestAuthorization()
                XCTFail("Expected to throw")
            } catch {
                XCTAssertEqual(error.appErrorCode, .cameraNotAuthorized)
            }
        }
    }

    // MARK: - Device selection

    func test_start_whenNoFrontDevice_throwsUnavailable_andQueriesBoth() async {
        let mock = MockCameraDeviceProvider()
        mock.authorizationStatusToReturn = .authorized
        mock.defaultDeviceToReturn = nil

        let sut = CameraManager(deviceProvider: mock)

        do {
            try await sut.start(delegate: DummyDelegate())
            XCTFail("Expected cameraUnavailable")
        } catch {
            XCTAssertEqual(error.appErrorCode, .cameraUnavailable)
        }

        XCTAssertEqual(mock.defaultDeviceCalls.count, 2)
    }

    // MARK: - ensureInput()

    func test_ensureInput_reusesMatchingInput() async throws {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        let output = MockVideoOutput()

        let existingInput = MockCaptureDeviceInput(device: device)
        session.inputsStorage = [existingInput]

        let creator = MockDeviceInputCreator()
        creator.nextInput = existingInput

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: output,
            inputCreator: creator
        )

        try await sut.start(delegate: DummyDelegate())
        XCTAssertEqual(session.inputsStorage.count, 1)
    }

    func test_ensureInput_replacesOldInput() async throws {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let oldDevice = MockCaptureDevice(uniqueID: "old")
        let newDevice = MockCaptureDevice(uniqueID: "new")

        dp.defaultDeviceToReturn = newDevice

        let oldInput = MockCaptureDeviceInput(device: oldDevice)
        let newInput = MockCaptureDeviceInput(device: newDevice)

        let session = MockCaptureSession()
        session.inputsStorage = [oldInput]

        let creator = MockDeviceInputCreator()
        creator.nextInput = newInput

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: MockVideoOutput(),
            inputCreator: creator
        )

        try await sut.start(delegate: DummyDelegate())

        XCTAssertEqual(session.inputsStorage.count, 1)
        XCTAssertEqual(session.inputsStorage.first?.captureDevice.uniqueID, "new")
    }

    func test_ensureInput_throwsWhenInputFactoryFails() async {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()

        let creator = MockDeviceInputCreator()
        creator.errorToThrow = NSError(domain: "x", code: 1)

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: MockVideoOutput(),
            inputCreator: creator
        )

        do {
            try await sut.start(delegate: DummyDelegate())
            XCTFail("Expected failure")
        } catch {
            XCTAssertEqual(error.appErrorCode, .cameraInputFailed)
        }
    }

    func test_ensureInput_throwsWhenSessionCannotAddInput() async {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        session.canAddInputResult = false

        let creator = MockDeviceInputCreator()
        creator.nextInput = MockCaptureDeviceInput(device: device)

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: MockVideoOutput(),
            inputCreator: creator
        )

        do {
            try await sut.start(delegate: DummyDelegate())
            XCTFail("Expected failure")
        } catch {
            XCTAssertEqual(error.appErrorCode, .cameraInputFailed)
        }
    }

    // MARK: - ensureOutput

    func test_ensureOutput_addedOnceOnly() async throws {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        let output = MockVideoOutput()

        let creator = MockDeviceInputCreator()
        creator.nextInput = MockCaptureDeviceInput(device: device)

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: output,
            inputCreator: creator
        )

        try await sut.start(delegate: DummyDelegate())
        try await sut.start(delegate: DummyDelegate())

        XCTAssertEqual(session.outputsStorage.count, 1)
    }

    func test_ensureOutput_throwsWhenCannotAddOutput() async {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        session.canAddOutputResult = false

        let creator = MockDeviceInputCreator()
        creator.nextInput = MockCaptureDeviceInput(device: device)

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: MockVideoOutput(),
            inputCreator: creator
        )

        do {
            try await sut.start(delegate: DummyDelegate())
            XCTFail("Expected failure")
        } catch {
            XCTAssertEqual(error.appErrorCode, .cameraOutputFailed)
        }
    }

    // MARK: - applyDelegate

    func test_applyDelegate_setsDelegateAndQueue() async throws {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        let output = MockVideoOutput()

        let creator = MockDeviceInputCreator()
        creator.nextInput = MockCaptureDeviceInput(device: device)

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: output,
            inputCreator: creator
        )

        let delegate = DummyDelegate()
        try await sut.start(delegate: delegate)

        XCTAssertTrue(output.lastDelegate === delegate)
        XCTAssertNotNil(output.lastQueue)
    }

    // MARK: - Connection tuning

    func test_applyConnectionTuning_requestsConnection() async throws {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        let output = MockVideoOutput()

        let creator = MockDeviceInputCreator()
        creator.nextInput = MockCaptureDeviceInput(device: device)

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: output,
            inputCreator: creator
        )

        try await sut.start(delegate: DummyDelegate())

        XCTAssertTrue(output.requestedConnections.contains(.video))
    }

    // MARK: - startSession

    func test_startSession_throwsWhenSessionFails() async {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        session.isRunningStorage = false // simulate failure

        let creator = MockDeviceInputCreator()
        creator.nextInput = MockCaptureDeviceInput(device: device)

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: MockVideoOutput(),
            inputCreator: creator
        )

        do {
            try await sut.start(delegate: DummyDelegate())
            XCTFail("Expected failure")
        } catch {
            XCTAssertEqual(error.appErrorCode, .cameraStartFailed)
        }
    }

    // MARK: - stop

    func test_stop_stopsSession_andClearsDelegate() async throws {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        let output = MockVideoOutput()

        let creator = MockDeviceInputCreator()
        creator.nextInput = MockCaptureDeviceInput(device: device)

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: output,
            inputCreator: creator
        )

        try await sut.start(delegate: DummyDelegate())
        sut.stop()

        XCTAssertTrue(session.stopRunningCalled)
        XCTAssertNil(output.lastDelegate)
    }
}
