import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject, Navigating {
    @Published var path: [Route] = []
    
    private let container: AppContainer
    private let errorManager: ErrorManager

    init(container: AppContainer, errorManager: ErrorManager) {
        self.container = container
        self.errorManager = errorManager
    }
    
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
                http: container.http,
                errorManager: errorManager,
                employeeId: id
            )
            VerificationView(viewModel: vm)
        }
    }
    
    func push(_ r: Route)     { path.append(r) }
    func pop()                { _ = path.popLast() }
}


