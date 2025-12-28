#if DEBUG
import SwiftUI
@testable import TradeTrackCore
@testable import TradeTrackMocks

struct PreviewApp: App {
    @StateObject private var errorManager = ErrorManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                //VerificationView(viewModel: .previewFailure(errorManager: errorManager))
                // VerificationView(viewModel: .previewSuccess(errorManager: errorManager))
                //LookupView(viewModel: .previewWithResults(errorManager: errorManager))
                //DashboardView(viewModel: .preview(errorManager: errorManager))
                DashboardView(viewModel: .previewAdmin(errorManager: errorManager))
                //DashboardView(viewModel: .previewWithError(errorManager: errorManager))
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
            camera: CoreFactory.makeCameraManager(),
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: CoreFactory.makeFaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: MockFaceVerificationService(),
            errorManager: errorManager,
            navigator: VerificationNavigator(nav: MockNavigator()),
            employee: employee
        )
    }

    static func previewFailure(errorManager: ErrorManager) -> VerificationViewModel {
        let service = MockFaceVerificationService()
        service.stubbedError = AppError(code: .employeeNotFound)
        let employee = EmployeeResult(employeeId: "EMP001", name: "Preview User", role: "Employee")
        
        return VerificationViewModel(
            camera: CoreFactory.makeCameraManager(),
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: CoreFactory.makeFaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: service,
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
}
#endif
