enum UserRole: String, RoleOption {
    case employee, admin

    var label: String { self.rawValue.capitalized }
    var icon: String {
        self == .employee ? "person" : "person.badge.key"
    }
}
