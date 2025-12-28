import TradeTrackCore

@MainActor
struct VerificationNavigator {
    private weak var nav: (any Navigating)?

    init(nav: any Navigating) { self.nav = nav }

    func goToDashboard(employee: EmployeeResult) {
        nav?.push(.dashboard(employee: employee))
    }

    func back() { nav?.pop() }
}
