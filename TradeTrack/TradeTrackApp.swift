import SwiftUI
import TradeTrackCore

/// Application entry point for TradeTrack.
///
/// Responsibilities:
/// - Determine the current runtime mode (production, preview, UI test, etc.)
/// - Build the dependency container exactly once
/// - Own long-lived global state objects (coordinator, error manager)
/// - Install the root navigation stack and global UI overlays
///
/// This type is intentionally *thin*:
/// no business logic, no feature decisions — just wiring.
@main
struct TradeTrackApp: App {

    /// Root dependency container.
    ///
    /// Built once at launch and passed down into the coordinator.
    /// This guarantees consistent dependencies across the entire app
    /// (including previews and UI tests).
    private let container: AppContainer

    /// Central navigation coordinator.
    ///
    /// Owns the navigation path and produces views for routes.
    /// Stored as a `StateObject` so it survives SwiftUI view reloads.
    @StateObject private var coordinator: AppCoordinator

    /// Global error manager.
    ///
    /// Responsible for surfacing app-level errors (network, camera, auth)
    /// in a consistent, user-visible way.
    /// Owned here so it lives for the lifetime of the app.
    @StateObject private var errorManager: ErrorManager

    /// App initializer.
    ///
    /// This is the *only* place where:
    /// - The runtime environment is inspected
    /// - The dependency graph is constructed
    /// - Global state objects are created
    ///
    /// If this initializer fails, the app cannot function, so a hard
    /// crash is preferred over undefined behavior.
    init() {
        let mode = AppRuntime.mode

        // Build dependency container for the selected runtime environment
        let builtContainer: AppContainer
        do {
            builtContainer = try AppContainer(environment: mode)
        } catch {
            fatalError("Failed to build AppContainer: \(error)")
        }

        // Create global error manager
        let em = ErrorManager()

        self.container = builtContainer

        // SwiftUI-managed lifetime for global state objects
        _errorManager = StateObject(wrappedValue: em)
        _coordinator = StateObject(
            wrappedValue: AppCoordinator(
                container: builtContainer,
                errorManager: em
            )
        )
    }

    /// Root scene.
    ///
    /// Sets up:
    /// - A `NavigationStack` driven by the coordinator
    /// - Route-based navigation using a typed `Route` enum
    /// - A global error banner overlay, independent of navigation state
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {

                // Initial screen
                coordinator.makeView(for: .lookup)
                    .navigationDestination(for: Route.self) { route in
                        coordinator.makeView(for: route)
                    }
            }
            // Make coordinator available to all descendant views
            .environmentObject(coordinator)

            // Global error presentation layer
            .overlay(alignment: .top) {
                ErrorBannerView(errorManager: errorManager)
                    .padding(.top, 10)
            }
        }
    }
}
