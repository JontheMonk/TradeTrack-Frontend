@MainActor
struct LookupNavigator {
    private weak var nav: (any Navigating)?

    init(nav: any Navigating) { self.nav = nav }

    func goToVerification(id: String) {
        nav?.push(.verification(employeeId: id))
    }

    func back() { nav?.pop() }
}
