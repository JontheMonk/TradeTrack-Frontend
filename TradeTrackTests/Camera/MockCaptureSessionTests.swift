import XCTest
@testable import TradeTrack

final class MockCaptureSessionTests: XCTestCase {

    func test_removeInput_removesExactObject() {
        let a = MockCaptureDeviceInput(device: MockCaptureDevice(uniqueID: "A"))
        let b = MockCaptureDeviceInput(device: MockCaptureDevice(uniqueID: "B"))

        let session = MockCaptureSession()
        session.inputs = [a, b]

        session.removeInput(a)

        XCTAssertEqual(session.inputs.count, 1)
        XCTAssertTrue(session.inputs.first === b)
    }

    func test_removeInput_doesNotRemoveDifferentObject() {
        let a1 = MockCaptureDeviceInput(device: MockCaptureDevice(uniqueID: "X"))
        let a2 = MockCaptureDeviceInput(device: MockCaptureDevice(uniqueID: "X"))

        let session = MockCaptureSession()
        session.inputs = [a1]

        session.removeInput(a2)

        XCTAssertEqual(session.inputs.count, 1)
        XCTAssertTrue(session.inputs.first === a1)
    }

    func test_removeInput_onEmptyList_doesNothing() {
        let session = MockCaptureSession()

        session.removeInput(MockCaptureDeviceInput(device: MockCaptureDevice()))

        XCTAssertTrue(session.inputs.isEmpty)
    }
}
