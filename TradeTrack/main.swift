import SwiftUI

if NSClassFromString("XCTestCase") != nil {
    // 1. Ghost App for Unit Tests
    TestApp.main()
} else if ProcessInfo.processInfo.arguments.contains("-preview") {
    // 2. Focused App for testing views
    PreviewApp.main()
} else {
    // 3. Normal App or UI Tests
    TradeTrackApp.main()
}
