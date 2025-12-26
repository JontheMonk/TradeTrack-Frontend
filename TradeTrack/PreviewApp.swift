import SwiftUI
import TradeTrackCore

struct PreviewApp: App {
    private var configuredViewModel: LookupViewModel {
        let mockService = MockEmployeeLookupService()
        
        mockService.stubbedResults = [
            EmployeeResult(employeeId: "101", name: "Jane Doe", role: "Manager"),
            EmployeeResult(employeeId: "102", name: "John Smith", role: "Technician")
        ]
        
        return LookupViewModel(
            service: mockService,
            errorManager: ErrorManager(),
            navigator: LookupNavigator(nav: MockNavigator())
        )
    }

    var body: some Scene {
        WindowGroup {
            LookupView(viewModel: configuredViewModel)
        }
    }
}
