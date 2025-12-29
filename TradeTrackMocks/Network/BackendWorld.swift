import Foundation

/// Describes the **simulated backend universe** the app should run against
/// during UI tests.
///
/// A `BackendWorld` represents a *complete, consistent backend state*
/// for the duration of a single app launch. UI tests select one world
/// at startup (via launch arguments), and **all network requests**
/// are answered according to that world's rules.
///
/// Important:
/// - A world is chosen **once**, at app launch
/// - The world does **not** change during runtime
/// - Each world defines which endpoints exist and what they return
///
/// Examples:
/// - `.employeeExistsAndMatches`:
///     - Employee search returns a match
///     - Verification succeeds
/// - `.employeeDoesNotExist`:
///     - Employee search returns empty
/// - `.verificationFails`:
///     - Verification endpoint returns failure
///
/// This keeps UI tests:
/// - deterministic
/// - fast
/// - independent of real backend state
enum BackendWorld: String {

    /// Backend behaves as if the employee exists and face verification succeeds.
    case employeeExistsAndMatches

    /// Backend behaves as if no matching employee exists.
    case employeeDoesNotExist

    /// Backend behaves as if verification is attempted but fails.
    case verificationFails

    /// Maps backend endpoints to JSON fixture filenames for this world.
    ///
    /// The keys represent *which endpoint* is being called,
    /// and the values represent *which JSON file* should be returned.
    ///
    /// If a request is made to an endpoint **not listed here**,
    /// the mock backend will fail loudly — by design.
    ///
    /// This prevents UI tests from silently passing when the app
    /// makes unexpected or unintended network calls.
    var fixtures: [MockEndpoint: String] {
        switch self {

        case .employeeExistsAndMatches:
            return [
                .employees: "employee_search_success",
                .verify: "verification_success",
                .clockStatus: "clock_status_clocked_out",
            ]

        case .employeeDoesNotExist:
            return [
                .employees: "employee_search_empty"
            ]

        case .verificationFails:
            return [
                .verify: "verification_failed"
            ]
        }
    }
}






