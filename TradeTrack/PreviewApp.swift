#if DEBUG
import SwiftUI
@testable import TradeTrackCore
@testable import TradeTrackMocks

struct PreviewApp: App {
    @StateObject private var errorManager = ErrorManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                //LookupView(viewModel: .previewWithResults(errorManager: errorManager))
                //LookupView(viewModel: .previewNoResults(errorManager: errorManager))
                //VerificationView(viewModel: .previewSuccess(errorManager: errorManager))
                //VerificationView(viewModel: .previewNoFace(errorManager: errorManager))
                //VerificationView(viewModel: .previewInvalidFace(errorManager: errorManager))
                //DashboardView(viewModel: .preview(errorManager: errorManager))
                //DashboardView(viewModel: .previewAdmin(errorManager: errorManager))
                //DashboardView(viewModel: .previewWithError(errorManager: errorManager))
                RegisterView(viewModel: .preview(errorManager: errorManager))
                //RegisterView(viewModel: .previewFilled(errorManager: errorManager))
            }
            .overlay(alignment: .top) {
                ErrorBannerView(errorManager: errorManager)
                    .padding(.top, 10)
            }
        }
    }
}

// MARK: - Dashboard Mocks
extension DashboardViewModel {
    static func preview(errorManager: ErrorManager) -> DashboardViewModel {
        let service = MockTimeTrackingService()
        let employee = EmployeeResult(employeeId: "EMP001", name: "Preview User", role: "Employee")
        
        return DashboardViewModel(
            employee: employee,
            timeService: service,
            errorManager: errorManager,
            navigator: DashboardNavigator(nav: MockNavigator())
        )
    }
    
    static func previewAdmin(errorManager: ErrorManager) -> DashboardViewModel {
        let service = MockTimeTrackingService()
        let employee = EmployeeResult(employeeId: "ADMIN001", name: "Preview User (Admin)", role: "Admin")
        
        return DashboardViewModel(
            employee: employee,
            timeService: service,
            errorManager: errorManager,
            navigator: DashboardNavigator(nav: MockNavigator())
        )
    }
    
    static func previewWithError(errorManager: ErrorManager) -> DashboardViewModel {
        let service = MockTimeTrackingService()
        service.stubbedError = AppError(code: .networkUnavailable)
        let employee = EmployeeResult(employeeId: "EMP001", name: "Preview User", role: "Employee")
        
        return DashboardViewModel(
            employee: employee,
            timeService: service,
            errorManager: errorManager,
            navigator: DashboardNavigator(nav: MockNavigator())
        )
    }
}

// MARK: - Verification Mocks
extension VerificationViewModel {
    static func previewSuccess(errorManager: ErrorManager) -> VerificationViewModel {
        let employee = EmployeeResult(employeeId: "EMP001", name: "Preview User", role: "Employee")
        
        return VerificationViewModel(
            camera: UITestCameraManager(world: .validFace),
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: CoreFactory.makeFaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: MockFaceVerificationService(),
            errorManager: errorManager,
            navigator: VerificationNavigator(nav: MockNavigator()),
            employee: employee
        )
    }
    
    static func previewNoFace(errorManager: ErrorManager) -> VerificationViewModel {
        let employee = EmployeeResult(employeeId: "EMP001", name: "Preview User", role: "Employee")
        
        return VerificationViewModel(
            camera: UITestCameraManager(world: .noFace),
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: CoreFactory.makeFaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: MockFaceVerificationService(),
            errorManager: errorManager,
            navigator: VerificationNavigator(nav: MockNavigator()),
            employee: employee
        )
    }
    
    static func previewInvalidFace(errorManager: ErrorManager) -> VerificationViewModel {
        let employee = EmployeeResult(employeeId: "EMP001", name: "Preview User", role: "Employee")
        
        return VerificationViewModel(
            camera: UITestCameraManager(world: .invalidFace),
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: CoreFactory.makeFaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: MockFaceVerificationService(),
            errorManager: errorManager,
            navigator: VerificationNavigator(nav: MockNavigator()),
            employee: employee
        )
    }
}

// MARK: - Lookup Mocks
extension LookupViewModel {
    static func previewWithResults(errorManager: ErrorManager) -> LookupViewModel {
        let service = MockEmployeeLookupService()
        service.stubbedResults = [EmployeeResult(employeeId: "123", name: "Preview User", role: "Admin")]
        
        return LookupViewModel(
            service: service,
            errorManager: errorManager,
            navigator: LookupNavigator(nav: MockNavigator())
        )
    }
    
    static func previewNoResults(errorManager: ErrorManager) -> LookupViewModel {
        let service = MockEmployeeLookupService()
        service.stubbedResults = []
        
        return LookupViewModel(
            service: service,
            errorManager: errorManager,
            navigator: LookupNavigator(nav: MockNavigator())
        )
    }
}


// MARK: - Register Mocks
extension RegisterViewModel {
    // Default - Empty form
    static func preview(errorManager: ErrorManager) -> RegisterViewModel {
        return RegisterViewModel(
            errorManager: errorManager,
            face: MockEmbeddingService(),
            api: MockRegistrationAPI()
        )
    }
    
    // Form filled out (user can manually select image in preview)
    static func previewFilled(errorManager: ErrorManager) -> RegisterViewModel {
        let vm = RegisterViewModel(
            errorManager: errorManager,
            face: MockEmbeddingService(),
            api: MockRegistrationAPI()
        )
        vm.employeeID = "EMP001"
        vm.name = "John Doe"
        vm.role = "Employee"
        return vm
    }
}
#endif
