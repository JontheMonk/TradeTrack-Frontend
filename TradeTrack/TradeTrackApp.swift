import SwiftUI
import Foundation

/// Entry point for the TradeTrack iOS application.
///
/// This struct initializes and wires together:
/// - The global dependency container (`AppContainer`)
/// - The global error manager (`ErrorManager`)
/// - The root coordinator (`AppCoordinator`)
///
/// It also hosts:
/// - The root `NavigationStack`
/// - A global top-mounted error banner
///
/// This is essentially the app’s **composition root**, responsible for creating
/// and injecting all shared services into the SwiftUI view hierarchy.
@main
struct TradeTrackApp: App {

    /// Global dependency container (face pipeline, camera, HTTP, etc.)
    private let container: AppContainer

    /// The root coordinator, controlling navigation across the whole app.
    @StateObject private var coordinator: AppCoordinator

    /// Centralized error manager used throughout the app.
    /// The error banner reads from this via `@ObservedObject`.
    @StateObject private var errorManager: ErrorManager

    // MARK: - Initialization

    /// Builds the dependency container and all top-level singletons.
    ///
    /// Any failure here is considered fatal because the app cannot function without:
    /// - A valid backend URL
    /// - Successfully constructed face-recognition pipeline
    ///
    init() {
        // Backend — fatalError because the app literally cannot run without this URL.
        guard let baseURL = URL(string: "https://tradetrack-backend.onrender.com") else {
            fatalError("Bad backend URL")
        }

        let http = HTTPClient(baseURL: baseURL)

        // Build full DI container (may throw if ML model fails to load)
        let builtContainer: AppContainer
        do {
            builtContainer = try AppContainer(http: http)
        } catch {
            fatalError("Failed to build AppContainer: \(error)")
        }

        // Global error manager
        let em = ErrorManager()

        // Inject
        self.container = builtContainer
        _errorManager = StateObject(wrappedValue: em)
        _coordinator = StateObject(
            wrappedValue: AppCoordinator(
                container: builtContainer,
                errorManager: em
            )
        )
    }

    // MARK: - Scene Graph

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {

                // Initial route
                coordinator.makeView(for: .lookup)
                    .navigationDestination(for: Route.self) { route in
                        coordinator.makeView(for: route)
                    }
            }
            .environmentObject(coordinator)

            // Global error banner overlay
            .overlay(alignment: .top) {
                ErrorBannerView(errorManager: errorManager)
                    .padding(.top, 10)
            }
        }
    }
}
