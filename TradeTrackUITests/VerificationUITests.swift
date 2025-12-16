//
//  VerificationUITests.swift
//
//  Deterministic UI tests for TradeTrack.
//  Every test declares its BackendWorld and CameraWorld explicitly.
//

import XCTest

// MARK: - Golden Path

final class LookupToVerificationSuccessUITests: BaseUITestCase {

    func test_lookupToVerification_success() {

        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "validFace"
        )

        // Lookup
        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("tes")

        // Results
        let result = app.buttons["lookup.result.test_user"]
        XCTAssertTrue(result.waitForExistence(timeout: 2))
        result.tap()

        // Verification
        let status = app.staticTexts["verification.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 2))

        // Processing → Success
        expectLabel(status, contains: "Verifying")
        expectLabel(status, contains: "Test User")
    }
}

// MARK: - Camera Worlds

final class CameraNoFaceUITests: BaseUITestCase {

    func test_noFace_staysDetecting() {

        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "noFace"
        )

        let status = app.staticTexts["verification.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 2))

        // Should remain in detecting state
        expectLabel(status, contains: "Looking")
    }
}

final class CameraInvalidFaceUITests: BaseUITestCase {

    func test_invalidFace_resetsToDetecting() {

        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "invalidFace"
        )

        let status = app.staticTexts["verification.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 2))

        // Invalid face should not progress
        expectLabel(status, contains: "Looking")
    }
}

final class CameraUnavailableUITests: BaseUITestCase {

    func test_cameraUnavailable_showsError() {

        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "cameraUnavailable"
        )

        let banner = app.staticTexts["error.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 2))
        XCTAssertTrue(banner.label.lowercased().contains("camera"))
    }
}

// MARK: - Backend Worlds

final class EmployeeNotFoundUITests: BaseUITestCase {

    func test_employeeDoesNotExist_showsNotFoundError() {

        launch(
            backendWorld: "employeeDoesNotExist",
            cameraWorld: "validFace"
        )

        let banner = app.staticTexts["error.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 2))
        XCTAssertTrue(banner.label.lowercased().contains("not found"))
    }
}

final class VerificationFailureUITests: BaseUITestCase {

    func test_verificationFails_showsErrorAndResets() {

        launch(
            backendWorld: "verificationFails",
            cameraWorld: "validFace"
        )

        let banner = app.staticTexts["error.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 2))

        let status = app.staticTexts["verification.status"]
        expectLabel(status, contains: "Looking")
    }
}
