struct EmployeeResult: Identifiable, Decodable {
    let employeeId: String
    let name: String
    let role: String

    var id: String { employeeId }
}
