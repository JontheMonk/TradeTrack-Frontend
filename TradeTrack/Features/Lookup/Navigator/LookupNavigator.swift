/// Lightweight wrapper that exposes only the navigation actions needed by the
/// Lookup screen.
///
/// Why this exists:
/// ----------------
/// `AppCoordinator` owns the real navigation stack.
/// But LookupViewModel shouldn’t know about the entire coordinator — it should
/// only receive a minimal, testable interface for the actions it cares about.
///
/// `LookupNavigator` holds a *weak* reference to the coordinator so we avoid
/// retain cycles, but still forward:
///   - `goToVerification` → push verification route
///   - `back` → pop the current route
///
/// This keeps LookupViewModel completely decoupled from the global navigation
/// architecture while still allowing full UI testability.
import TradeTrackCore

@MainActor
struct LookupNavigator {
    private weak var nav: (any Navigating)?

    init(nav: any Navigating) { self.nav = nav }

    func goToVerification(id: String) {
        nav?.push(.verification(employeeId: id))
    }

    func back() { nav?.pop() }
}
