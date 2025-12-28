import TradeTrackCore

@MainActor
struct VerificationNavigator {
    private weak var nav: (any Navigating)?

    init(nav: any Navigating) { self.nav = nav }

    func goToDashboard(employeeId: String) {
        nav?.push(.dashboard(employeeId: employeeId))
    }

    func back() { nav?.pop() }
}
