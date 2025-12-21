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

        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("test_user")

        let result = app.buttons["lookup.result.test_user"]
        XCTAssertTrue(result.waitForExistence(timeout: 2))
        result.tap()
        
        let statusLabel = app.staticTexts["verification.status_indicator"]
        
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 10), "Status indicator ID not found")

        XCTAssertEqual(statusLabel.label, "Welcome, Test User")
    }
}

// MARK: - Camera Worlds

final class CameraNoFaceUITests: BaseUITestCase {

    func test_noFace_staysDetecting() {

        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "noFace"
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

        // Detecting
        expectLabel(status, contains: "Looking")

        // Still detecting (no silent progress)
        XCTAssertFalse(status.label.contains("Verifying"))
    }

}

final class CameraInvalidFaceUITests: BaseUITestCase {

    func test_invalidFace_resetsToDetecting_andShowsError() {

        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "invalidFace"
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

        let status = app.staticTexts["verification.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 2))

        expectLabel(status, contains: "Looking")

        let banner = app.staticTexts["error.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 2))
    }

}

final class CameraUnavailableUITests: BaseUITestCase {

    func test_cameraUnavailable_showsError() {

        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "cameraUnavailable"
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
        
        // Lookup
        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("tes")

        let banner = app.staticTexts["error.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 2))
        XCTAssertTrue(banner.label.lowercased().contains("not found"))
    }
}
