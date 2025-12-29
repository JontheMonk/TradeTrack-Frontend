//
//  VerificationUITests.swift
//
//  Deterministic UI tests for TradeTrack.
//  Updated to match new SwiftUI View hierarchy and Accessibility Traits.
//

import XCTest

// MARK: - Camera Worlds

final class CameraNoFaceUITests: BaseUITestCase {

    func test_noFace_staysDetecting() {
        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "noFace"
        )

        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("test_user")

        let result = app.buttons["lookup.result.test_user"]
        XCTAssertTrue(result.waitForExistence(timeout: 2))
        result.tap()

        let statusLabel = app.staticTexts["verification.status_indicator"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 10))

        // Matches: .detecting state when progress is low (< 0.05)
        XCTAssertEqual(statusLabel.label, "Align Face")
    }
}

final class CameraInvalidFaceUITests: BaseUITestCase {

    func test_invalidFace_resetsToDetecting_andShowsError() {
        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "invalidFace"
        )
        
        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("test_user")

        let result = app.buttons["lookup.result.test_user"]
        XCTAssertTrue(result.waitForExistence(timeout: 2))
        result.tap()

        let statusLabel = app.staticTexts["verification.status_indicator"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 10))

        // Even with an error, the view stays in .detecting mode
        XCTAssertEqual(statusLabel.label, "Align Face")

        // Verify the error message appears
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
        
        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("test_user")

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
        
        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("unknown_user")

        // In this scenario, the list should be empty or show an error banner
        let banner = app.staticTexts["error.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 2))
        XCTAssertTrue(banner.label.lowercased().contains("not found"))
    }
}


final class VerificationToDashboardUITests: BaseUITestCase {
    
    func test_verificationSuccess_navigatesToDashboard() {
        launch(
            backendWorld: "employeeExistsAndMatches",
            cameraWorld: "validFace"
        )
        
        // 1. Go through lookup
        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("test_user")
        
        let result = app.buttons["lookup.result.test_user"]
        XCTAssertTrue(result.waitForExistence(timeout: 2))
        result.tap()
        
        // 2. Wait for navigation to dashboard (1.5s delay + transition)
        // Skip checking the transient "Welcome" message - it's too fast
        let clockButton = app.buttons["dashboard.clock_button"]
        XCTAssertTrue(clockButton.waitForExistence(timeout: 5), "Dashboard should appear after successful verification")
        
        // 3. Verify dashboard content
        let status = app.staticTexts["dashboard.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 1))
        XCTAssertEqual(status.label, "OFF SHIFT", "Should show initial clocked-out state")
    }
}
