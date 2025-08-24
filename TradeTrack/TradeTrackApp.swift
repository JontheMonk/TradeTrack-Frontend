import SwiftUI
import Foundation

@main
struct TradeTrackApp: App {
    private let container: AppContainer
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var errorManager: ErrorManager

    init() {
        guard let baseURL = URL(string: "https://tradetrack-backend.onrender.com") else {
            fatalError("Bad backend URL")
        }
        let http = HTTPClient(baseURL: baseURL)

        let builtContainer: AppContainer
        do {
            builtContainer = try AppContainer(http: http)
        } catch {
            fatalError("Failed to build AppContainer: \(error)")
        }

        let em = ErrorManager()
        self.container = builtContainer
        _errorManager = StateObject(wrappedValue: em)
        _coordinator = StateObject(wrappedValue: AppCoordinator(container: builtContainer, errorManager: em))
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
