import XCTest
@testable import TradeTrackCore

/// Unit tests for `MockCaptureSession`.
///
/// These tests focus specifically on the semantics of `removeInput(...)`,
/// because the mock is intentionally implemented using **object identity**
/// (`===`) rather than value-based comparisons.
///
/// Why identity matters:
/// ----------------------
/// AVFoundation’s `AVCaptureSession` tracks inputs by object identity.
/// Two `AVCaptureDeviceInput` instances may wrap devices with the same
/// `uniqueID`, but the session considers them distinct objects.
/// The mock mirrors that behavior to ensure tests reflect real-world rules.
///
/// These tests verify:
///   - The correct object is removed when it *is* the exact instance
///   - Different instances with identical content are *not* treated as equal
///   - Calling removal on an empty list is safe and produces no side effects
final class MockCaptureSessionTests: XCTestCase {

    // MARK: - Exact object removal

    /// Ensures that calling `removeInput` removes the **exact** object instance
    /// passed to it — matching AVFoundation semantics.
    func test_removeInput_removesExactObject() {
        let a = MockCaptureDeviceInput(device: MockCaptureDevice(uniqueID: "A"))
        let b = MockCaptureDeviceInput(device: MockCaptureDevice(uniqueID: "B"))

        let session = MockCaptureSession()
        session.inputs = [a, b]

        session.removeInput(a)

        XCTAssertEqual(session.inputs.count, 1)
        XCTAssertTrue(session.inputs.first === b)
    }

    // MARK: - Identity, not value

    /// Ensures that `removeInput` does **not** remove a different object,
    /// even if the underlying device has the same uniqueID or properties.
    ///
    /// This explicitly tests identity comparison (`===`) rather than
    /// value comparison, mirroring how real AVCaptureSessions behave.
    func test_removeInput_doesNotRemoveDifferentObject() {
        let a1 = MockCaptureDeviceInput(device: MockCaptureDevice(uniqueID: "X"))
        let a2 = MockCaptureDeviceInput(device: MockCaptureDevice(uniqueID: "X"))

        let session = MockCaptureSession()
        session.inputs = [a1]

        session.removeInput(a2)

        XCTAssertEqual(session.inputs.count, 1)
        XCTAssertTrue(session.inputs.first === a1)
    }

    // MARK: - Empty list edge case

    /// Verifies that calling `removeInput` on a session with no inputs
    /// does nothing and does not crash. Defensive behavior expected from a mock.
    func test_removeInput_onEmptyList_doesNothing() {
        let session = MockCaptureSession()

        session.removeInput(MockCaptureDeviceInput(device: MockCaptureDevice()))

        XCTAssertTrue(session.inputs.isEmpty)
    }
}
