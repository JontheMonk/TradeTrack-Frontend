/// Abstraction for fetching employees whose IDs or names match a given prefix.
///
/// Why this exists:
/// ----------------
/// View models (like `LookupViewModel`) shouldn’t know about networking,
/// URLs, HTTP verbs, or backend response formats.
/// They should depend only on **what** they need:
/// “Given a prefix, return matching employees.”
///
/// This protocol makes the lookup logic:
///   • testable (you can inject a mock service)
///   • decoupled from HTTPClient
///   • flexible if backend endpoints ever change
protocol EmployeeLookupServing {
    /// Searches the backend for employees whose identifiers begin with `prefix`.
    ///
    /// - Parameter prefix: The beginning of the employee ID or name.
    /// - Returns: An array of matching `EmployeeResult`. Returns `[]` if the
    ///   server returns no data or the response is empty.
    func search(prefix: String) async throws -> [EmployeeResult]
}


/// Production implementation of `EmployeeLookupServing` backed by `HTTPClient`.
///
/// Handles the GET `/employees?prefix=...` call and unwraps the server’s
/// `APIResponse<[EmployeeResult]>`.
/// If the server returns `success: true` but no `data`, this safely produces
/// an empty array instead of `nil`.
struct EmployeeLookupService: EmployeeLookupServing {
    let http: HTTPClient

    func search(prefix: String) async throws -> [EmployeeResult] {
        try await http.send(
            "GET",
            path: "employees",
            query: ["prefix": prefix]
        ) ?? []
    }
}

