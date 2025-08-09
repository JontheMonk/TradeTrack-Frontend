struct EmployeeLookupService: EmployeeLookupServing {
    let http: HTTPClient
    func search(prefix: String) async throws -> [EmployeeResult] {
        try await http.send("GET", path: "employees", query: ["prefix": prefix]) ?? []
    }
}
