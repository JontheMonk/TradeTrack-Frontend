/// Minimal abstraction for presenting errors to the UI.
///
/// View models should never depend directly on `ErrorManager` — the concrete
/// app-wide error presenter — because that would make them:
///   • difficult to unit test
///   • tightly coupled to global UI state
///   • unable to run in isolation
///
/// `ErrorHandling` exposes just the one capability VMs need:
/// reporting errors that should surface to the user.
///
/// Conforming types:
///   • `ErrorManager` (production) — logs errors and shows banners
///   • `MockErrorManager` (tests) — captures the last error for assertions
///
/// By depending on this protocol instead of the concrete class, view models
/// become fully testable and independent from UI infrastructure.
public protocol ErrorHandling {
    /// Notify the handler that an error occurred and should be presented.
    ///
    /// Implementations may log, normalize, or publish UI state.
    /// Tests typically use a lightweight mock that records the error.
    func showError(_ error: Error)
}
