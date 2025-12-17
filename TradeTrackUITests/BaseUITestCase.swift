import XCTest

class BaseUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func launch(
        backendWorld: String,
        cameraWorld: String
    ) {
        app.launchArguments = [
            "-UITest",
            "-BackendWorld", backendWorld,
            "-CameraWorld", cameraWorld
        ]
        app.launch()
    }
    
    /// Waits for a label to contain text (predicate-based, no sleeps).
    func expectLabel(
        _ element: XCUIElement,
        contains text: String,
        timeout: TimeInterval = 3
    ) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTWaiter().wait(for: [exp], timeout: timeout)
    }
}
