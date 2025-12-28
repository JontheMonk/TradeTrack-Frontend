import TradeTrackCore

@MainActor
struct DashboardNavigator {
    private weak var nav: (any Navigating)?

    init(nav: any Navigating) { self.nav = nav }

    func signOut() {
        nav?.popToRoot()
    }

    func goToRegister() {
        nav?.push(.register)
    }
}
