@MainActor
protocol Navigating: AnyObject {
    func push(_ route: Route)
    func pop()
}
