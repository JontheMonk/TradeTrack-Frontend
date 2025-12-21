import XCTest
import AVFoundation
@testable import TradeTrackCore

/// Dummy delegate used as a stand-in for AVCaptureVideoDataOutput callbacks.
final class DummyDelegate: NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {}

///
/// Tests for `CameraManager`.
///
/// These tests verify:
///   - Camera authorization behavior
///   - Device selection logic when choosing front cameras
///   - Input setup behavior (reuse, replacement, error handling)
///   - Output setup behavior (added once, failure cases)
///   - Delegate assignment
///   - Connection tuning calls
///   - Session start/stop behavior
///
/// Mocks are used to simulate AVFoundation without hitting hardware.
///
final class CameraManagerTests: XCTestCase {

    // MARK: - Authorization ----------------------------------------------------

    /// When already authorized, `requestAuthorization()` should finish without prompting.
    func test_requestAuthorization_authorized_succeeds_withoutPrompt() async throws {
        let mock = MockCameraDeviceProvider()
        mock.authorizationStatusToReturn = .authorized

        let sut = CameraManager(deviceProvider: mock)
        try await sut.requestAuthorization()

        XCTAssertEqual(mock.authorizationStatusCalls, [.video])
        XCTAssertTrue(mock.requestAccessCalls.isEmpty)
    }

    /// If authorization is `.notDetermined` and the user grants access, authorization succeeds.
    func test_requestAuthorization_notDetermined_granted_succeeds() async throws {
        let mock = MockCameraDeviceProvider()
        mock.authorizationStatusToReturn = .notDetermined
        mock.requestAccessResult = true

        let sut = CameraManager(deviceProvider: mock)
        try await sut.requestAuthorization()

        XCTAssertEqual(mock.authorizationStatusCalls, [.video])
        XCTAssertEqual(mock.requestAccessCalls, [.video])
    }

    /// `.notDetermined` + user denies access → throws `.cameraNotAuthorized`.
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

    /// `.denied` or `.restricted` always throws `.cameraNotAuthorized`.
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


    // MARK: - Device Selection -------------------------------------------------

    /// When neither TrueDepth nor WideAngle front cameras are available,
    /// `.start()` throws `.cameraUnavailable` and checks both device types.
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

        // Should have asked for TrueDepth THEN WideAngle
        XCTAssertEqual(mock.defaultDeviceCalls.count, 2)
    }


    // MARK: - ensureInput() ---------------------------------------------------

    /// If the session already contains an input for the same device,
    /// the manager should reuse it instead of recreating anything.
    func test_ensureInput_reusesMatchingInput() async throws {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        let output = MockVideoOutput()

        let existingInput = MockCaptureDeviceInput(device: device)
        session.inputs = [existingInput]

        let creator = MockDeviceInputCreator()
        creator.nextInput = existingInput

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: output,
            inputCreator: creator
        )

        try await sut.start(delegate: DummyDelegate())
        XCTAssertEqual(session.inputs.count, 1)
    }

    /// If the existing input belongs to a different device, it should be removed
    /// and replaced with a new input for the correct device.
    func test_ensureInput_replacesOldInput() async throws {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let oldDevice = MockCaptureDevice(uniqueID: "old")
        let newDevice = MockCaptureDevice(uniqueID: "new")

        dp.defaultDeviceToReturn = newDevice

        let oldInput = MockCaptureDeviceInput(device: oldDevice)
        let newInput = MockCaptureDeviceInput(device: newDevice)

        let session = MockCaptureSession()
        session.inputs = [oldInput]

        let creator = MockDeviceInputCreator()
        creator.nextInput = newInput

        let sut = CameraManager(
            deviceProvider: dp,
            session: session,
            output: MockVideoOutput(),
            inputCreator: creator
        )

        try await sut.start(delegate: DummyDelegate())
        XCTAssertEqual(session.inputs.count, 1)
        XCTAssertEqual(session.inputs.first?.captureDevice.uniqueID, "new")
    }

    /// If the DeviceInputFactory fails, ensureInput should surface `.cameraInputFailed`.
    func test_ensureInput_throwsWhenInputFactoryFails() async {
        enum MockError: Error { case boom }
        
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()

        let creator = MockDeviceInputCreator()
        creator.errorToThrow = MockError.boom

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

    /// If the session refuses the input, `.cameraInputFailed` should be thrown.
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


    // MARK: - ensureOutput() --------------------------------------------------

    /// Output should only ever be added once per CameraManager instance.
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

        XCTAssertEqual(session.outputs.count, 1)
    }

    /// If session refuses an output, throw `.cameraOutputFailed`.
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


    // MARK: - Delegate Assignment --------------------------------------------

    /// Ensure that applyDelegate correctly forwards the delegate and queue.
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


    // MARK: - Connection Tuning ----------------------------------------------

    /// Verifies that the manager requests a connection for `.video`,
    /// allowing tuning logic to apply mirroring/orientation.
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


    // MARK: - startSession ----------------------------------------------------

    /// If `startRunning()` fails (mocked), throw `.cameraStartFailed`.
    func test_startSession_throwsWhenSessionFails() async {
        let dp = MockCameraDeviceProvider()
        dp.authorizationStatusToReturn = .authorized

        let device = MockCaptureDevice()
        dp.defaultDeviceToReturn = device

        let session = MockCaptureSession()
        session.shouldStartRunningSucceed = false

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


    // MARK: - stop() ----------------------------------------------------------

    /// `stop()` should call `stopRunning()` and clear the video delegate.
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
        await sut.stop()

        XCTAssertTrue(session.stopRunningCalled)
        XCTAssertNil(output.lastDelegate)
    }
}
