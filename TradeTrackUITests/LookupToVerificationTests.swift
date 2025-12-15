import XCTest

final class LookupToVerificationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["-UITest"]
        app.launch()
    }

    /// Golden path:
    /// Lookup → select employee → verification → success
    func test_lookupToVerification_success() {

        // MARK: - Lookup Screen

        let searchField = app.textFields["lookup.search"]
        XCTAssertTrue(
            searchField.waitForExistence(timeout: 2),
            "Lookup search field should exist"
        )

        searchField.tap()
        searchField.typeText("tes") // ≥ 3 chars triggers search

        // MARK: - Results

        let firstResult = app.buttons["lookup.result.test_user"]
        XCTAssertTrue(
            firstResult.waitForExistence(timeout: 2),
            "Expected a test employee result"
        )

        firstResult.tap()

        // MARK: - Verification Screen

        let statusLabel = app.staticTexts["verification.status"]
        XCTAssertTrue(
            statusLabel.waitForExistence(timeout: 2),
            "Verification status should appear"
        )

        // MARK: - State Transitions

        XCTAssertTrue(
            statusLabel.waitForExistence(timeout: 2),
            "Initial verification state should be visible"
        )

        let verifyingPredicate = NSPredicate(format: "label CONTAINS %@", "Verifying")
        expectation(for: verifyingPredicate, evaluatedWith: statusLabel)
        waitForExpectations(timeout: 3)

        let successPredicate = NSPredicate(format: "label CONTAINS %@", "Test User")
        expectation(for: successPredicate, evaluatedWith: statusLabel)
        waitForExpectations(timeout: 3)
    }
}
