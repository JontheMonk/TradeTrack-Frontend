import SwiftUI
/// A "Ghost App" that does nothing.
/// This ensures Unit Tests don't trigger production initializers.
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Running Unit Tests...")
        }
    }
}
