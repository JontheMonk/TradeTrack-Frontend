struct EmployeeResult: Identifiable, Decodable {
    let employeeId: String
    let name: String
    let role: String

    var id: String { employeeId }

    enum CodingKeys: String, CodingKey {
        case employeeId = "employee_id"
        case name
        case role
    }
}
