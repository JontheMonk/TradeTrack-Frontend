import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [Route] = []
    private let container: AppContainer

    init(container: AppContainer) { self.container = container }

    func push(_ route: Route) { path.append(route) }
    func pop() { _ = path.popLast() }

    @ViewBuilder
    func makeView(for route: Route) -> some View {
        switch route {
        case .lookup:
            let vm = LookupViewModel(
                service: container.employeeLookupService,
                errorManager: container.errorManager
            )
            LookupView(viewModel: vm)

        case .verification(let employeeId):
            let vm = VerificationViewModel(
                http: container.http,
                errorManager: container.errorManager,
                employeeId: employeeId
            )
            VerificationView(viewModel: vm)
        }
    }

}
