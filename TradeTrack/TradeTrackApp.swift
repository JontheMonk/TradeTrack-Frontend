import SwiftUI

@main
struct TradeTrackApp: App {
    @StateObject private var errorManager = ErrorManager()

    private let http: HTTPClient
    private let lookupService: EmployeeLookupService

    init() {
        let baseURL = URL(string: "https://tradetrack-backend.onrender.com")!
        let http = HTTPClient(baseURL: baseURL)
        self.http = http
        self.lookupService = EmployeeLookupService(http: http)
    }

    var body: some Scene {
        WindowGroup {
            LookupView(service: lookupService, errorManager: errorManager, http: http)
                .overlay(alignment: .top) { ErrorBannerView().padding(.top, 10) }
                .environmentObject(errorManager)
        }
    }
}
