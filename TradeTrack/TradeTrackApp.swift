import SwiftUI

@main
struct TradeTrackApp: App {

    private let container: AppContainer
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var errorManager: ErrorManager

    init() {
        let mode = AppRuntime.mode

        // Build dependency container
        let builtContainer: AppContainer
        do {
            builtContainer = try AppContainer(environment: mode)
        } catch {
            fatalError("Failed to build AppContainer: \(error)")
        }

        let em = ErrorManager()

        self.container = builtContainer
        _errorManager = StateObject(wrappedValue: em)
        _coordinator = StateObject(
            wrappedValue: AppCoordinator(
                container: builtContainer,
                errorManager: em
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                coordinator.makeView(for: .lookup)
                    .navigationDestination(for: Route.self) { route in
                        coordinator.makeView(for: route)
                    }
            }
            .environmentObject(coordinator)
            .overlay(alignment: .top) {
                ErrorBannerView(errorManager: errorManager)
                    .padding(.top, 10)
            }
        }
    }
}
