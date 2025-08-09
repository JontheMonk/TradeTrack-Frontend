protocol EmployeeRegistrationServing {
    func addEmployee(_ input: EmployeeInput) async throws
}

struct EmployeeRegistrationService: EmployeeRegistrationServing {
    let http: HTTPClient
    func addEmployee(_ input: EmployeeInput) async throws {
        let _: Empty? = try await http.send("POST", path: "add-employee", body: input)
    }
}
