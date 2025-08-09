import SwiftUI

@main
struct TradeTrackApp: App {
    @StateObject private var errorManager = ErrorManager()
    private let http = HTTPClient(baseURL: URL(string: "https://tradetrack-backend.onrender.com")!)

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                RegisterView(http: http, errorManager: errorManager)
                ErrorBannerView()
                    .padding(.top, 10)
                    .zIndex(1)
            }
            .environmentObject(errorManager)
        }
    }
}
