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
                DashboardView(viewModel: .previewClockedOut(errorManager: errorManager))
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
    static func previewClockedOut(errorManager: ErrorManager) -> DashboardViewModel {
        let service = MockTimeTrackingService()
        service.stubbedStatus = ClockStatus(isClockedIn: false, clockInTime: nil)
        
        return DashboardViewModel(
            employeeId: "EMP001",
            timeService: service,
            errorManager: errorManager
        )
    }
}

// MARK: - Verification Mocks
extension VerificationViewModel {
    static func previewSuccess(errorManager: ErrorManager) -> VerificationViewModel {
        return VerificationViewModel(
            camera: CoreFactory.makeCameraManager(),
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: CoreFactory.makeFaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: MockFaceVerificationService(),
            errorManager: errorManager,
            employeeId: "Preview_User"
        )
    }

    static func previewFailure(errorManager: ErrorManager) -> VerificationViewModel {
        let service = MockFaceVerificationService()
        service.stubbedError = AppError(code: .employeeNotFound)
        
        return VerificationViewModel(
            camera: CoreFactory.makeCameraManager(),
            analyzer: CoreFactory.makeFaceAnalyzer(),
            collector: CoreFactory.makeFaceCollector(),
            processor: try! CoreFactory.makeFaceProcessor(),
            verifier: service,
            errorManager: errorManager,
            employeeId: "Preview_User"
        )
    }
}

// MARK: - Lookup Mocks
extension LookupViewModel {
    static func previewWithResults(errorManager: ErrorManager) -> LookupViewModel {
        let service = MockEmployeeLookupService()
        service.stubbedResults = [EmployeeResult(employeeId: "123", name: "Jon", role: "Admin")]
        
        return LookupViewModel(
            service: service,
            errorManager: errorManager, // Injected from App
            navigator: LookupNavigator(nav: MockNavigator())
        )
    }
}
#endif
