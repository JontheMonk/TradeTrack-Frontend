import SwiftUI

@main
struct TradeTrackApp: App {
    @StateObject private var errorManager = ErrorManager()
    private let http = HTTPClient(baseURL: URL(string: "https://tradetrack-backend.onrender.com")!)
    private let lookupService: EmployeeLookupServing

    init() {
        self.lookupService = EmployeeLookupService(http: http) // or whatever your service is
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                LookupView(service: lookupService, errorManager: errorManager)
                ErrorBannerView()
                    .padding(.top, 10)
                    .zIndex(1)
            }
            .environmentObject(errorManager)
        }
    }
}
