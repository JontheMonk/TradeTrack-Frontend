import Foundation
@testable import TradeTrack

/// A lightweight test double for `Navigating`.
///
/// `LookupViewModel` interacts with navigation only through the `Navigating`
/// protocol (wrapped by `LookupNavigator`).
/// In unit tests, we replace the real app coordinator with this mock so we can:
///
///   • capture which routes were pushed
///   • count how many times `pop()` was called
///   • assert navigation behavior without touching UI or SwiftUI state
///
/// This mock does **not** perform any real navigation — it simply records calls.
/// Tests then inspect `pushed` and `popCount` to verify correct behavior.
final class MockNavigator: Navigating {

    /// Every route pushed by the ViewModel.
    ///
    /// Stored with `private(set)` so tests may read but not mutate it.
    private(set) var pushed: [Route] = []

    /// Number of times `pop()` was invoked.
    ///
    /// Useful for verifying back-navigation behavior.
    private(set) var popCount: Int = 0

    /// Records a navigation push request.
    func push(_ route: Route) {
        pushed.append(route)
    }

    /// Records a back-navigation request.
    func pop() {
        popCount += 1
    }
}
