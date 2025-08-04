import SwiftUI

@main
struct TradeTrackApp: App {
    @StateObject private var errorManager = ErrorManager()

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                RegisterView()
                ErrorBannerView()
                    .padding(.top, 10)
                    .zIndex(1)
            }
            .environmentObject(errorManager)
        }
    }
}
