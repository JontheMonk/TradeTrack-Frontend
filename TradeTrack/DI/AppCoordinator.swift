//
//  AppCoordinator.swift
//
//  Central navigation coordinator for the app.
//
//  `AppCoordinator` owns the SwiftUI navigation path and constructs feature
//  view models on-demand using dependencies from `AppContainer`. This keeps
//  routing logic out of the views and gives the app a single place where
//  navigation + dependency wiring is controlled.
//
//  The coordinator follows the typical iOS pattern:
//  - holds navigation state (`path`)
//  - pushes/pops routes
//  - builds views for a given route
//
//  Views never directly construct their own dependencies; they ask the
//  coordinator to build view models and supply the correct services.
//

import SwiftUI
import TradeTrackCore

/// High-level navigation coordinator responsible for pushing views,
/// constructing view models, and wiring dependencies from `AppContainer`.
///
/// `AppCoordinator` acts as the single source of truth for app navigation.
/// It conforms to `Navigating`, giving feature modules an abstract way to
/// push/pop without depending on SwiftUI directly.
///
/// ### Responsibilities
/// - maintain SwiftUI’s navigation path
/// - build feature-specific view models with the correct dependencies
/// - hide all DI wiring from views
/// - centralize error handling via `ErrorManager`
///
/// This setup keeps views lightweight and promotes proper testability:
/// coordinators handle navigation, containers build dependencies,
/// and view models focus strictly on logic.
@MainActor
final class AppCoordinator: ObservableObject, Navigating {

    /// Current navigation stack (SwiftUI NavigationPath-style).
    @Published var path: [Route] = []
    
    /// Dependency container with all core services + pipelines.
    private let container: AppContainer

    /// Centralized error-handling and surface-presenting utility.
    private let errorManager: ErrorManager

    /// Creates a new coordinator with injected dependencies.
    ///
    /// - Parameters:
    ///   - container: The app’s dependency container.
    ///   - errorManager: Handles error presentation for all screens.
    init(container: AppContainer, errorManager: ErrorManager) {
        self.container = container
        self.errorManager = errorManager
    }
    
    // MARK: - View Construction

    /// Builds the SwiftUI view associated with a navigation route.
    ///
    /// Each case constructs the appropriate view model with the correct
    /// dependencies and wraps it in its corresponding screen.
    ///
    /// This ensures:
    /// - view models remain lightweight and dependency-free
    /// - DI is centralized
    /// - navigation logic stays out of screens
    @ViewBuilder
    func makeView(for route: Route) -> some View {
        switch route {

        case .lookup:
            let vm = LookupViewModel(
                service: container.employeeLookupService,
                errorManager: errorManager,
                navigator: LookupNavigator(nav: self)
            )
            LookupView(viewModel: vm)

        case .verification(let id):
            let vm = VerificationViewModel(
                camera: container.cameraManager,
                analyzer: container.faceAnalyzer,
                collector:  container.faceCollector,
                processor: container.faceProcessor,
                verifier: container.faceVerificationService,
                errorManager: errorManager,
                navigator: VerificationNavigator(nav: self),
                employeeId: id
            )
            VerificationView(viewModel: vm)
            
        case .dashboard(let id):
            let vm = DashboardViewModel(
                employeeId: id,
                timeService: container.timeTrackingService,
                errorManager: errorManager,
                navigator: DashboardNavigator(nav: self)
            )
            DashboardView(viewModel: vm)
            
        case .register:
            let vm = RegisterViewModel(
                errorManager: errorManager,
                face: container.registrationService,
                api: container.employeeAPI
            )
            RegisterView(viewModel: vm)
        
        @unknown default:
            EmptyView()
        }
        
        
    }
    
    // MARK: - Navigation API

    /// Pushes a new route onto the navigation stack.
    func push(_ r: Route) {
        path.append(r)
    }

    /// Pops the topmost route from the navigation stack.
    func pop() {
        _ = path.popLast()
    }
    
    /// Clears stack
    func popToRoot() {
        path.removeAll()
    }
}
