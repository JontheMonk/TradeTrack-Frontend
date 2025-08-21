enum Route: Hashable {
    case lookup
    case verification(employeeId: String)
    case register
}
