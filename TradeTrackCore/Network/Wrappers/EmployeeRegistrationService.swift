/// Service responsible for registering new employees with the backend.
///
/// This abstraction allows the UI and ViewModels to depend on a simple
/// protocol (`EmployeeRegistrationServing`) instead of directly touching
/// networking code or `HTTPClient`.
///
/// The concrete implementation sends a `POST /add-employee` request with
/// an `EmployeeInput` payload. The backend is expected to return a generic
/// `APIResponse<Empty>`.
///
/// Errors:
///  • Network failures, decoding issues, or backend error codes are all
///    surfaced as `AppError` via the `HTTPClient`.
///  • Callers should handle these errors and display an appropriate message
///    through `ErrorManager`.
public protocol EmployeeRegistrationServing {
    /// Registers a new employee with their metadata and face embedding.
    ///
    /// - Parameter input: The full employee record including ID, name, role,
    ///   and normalized 512-dimensional face embedding.
    /// - Throws: `AppError` if the network request fails or the backend
    ///   reports an error.
    func addEmployee(_ input: EmployeeInput) async throws
}

/// Default implementation of `EmployeeRegistrationServing` backed by `HTTPClient`.
struct EmployeeRegistrationService: EmployeeRegistrationServing {
    let http: HTTPClient
    let adminKey: String

    func addEmployee(_ input: EmployeeInput) async throws {
        let _: Empty? = try await http.send(
            "POST",
            path: APIPaths.register,
            body: input,
            headers: ["X-Admin-Key": adminKey]
        )
    }
}
