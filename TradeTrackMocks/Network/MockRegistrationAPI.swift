import Foundation
import TradeTrackCore

/// Test double for `EmployeeRegistrationServing`.
///
/// This mock replaces the real registration API call (`POST /add-employee`)
/// with a synchronous, fully controlled implementation.
///
/// It allows `RegisterViewModel` tests to:
///   • verify that the API is called exactly once per submission
///   • inspect the exact `EmployeeInput` sent by the ViewModel
///   • simulate backend failures deterministically
///
/// Because no real networking or encoding happens, tests remain isolated,
/// fast, and completely deterministic.
final class MockRegistrationAPI: EmployeeRegistrationServing {

    /// Number of times `addEmployee(_:)` was invoked.
    ///
    /// Useful for asserting that:
    ///   • only one registration attempt occurs
    ///   • duplicate submissions are ignored
    private(set) var callCount = 0

    /// The last `EmployeeInput` passed into the mock.
    ///
    /// Allows deep inspection of:
    ///   • normalized embeddings
    ///   • trimmed employeeId / name / role
    ///   • correct forwarding of data from the ViewModel
    private(set) var lastInput: EmployeeInput?

    /// Optional error used to simulate backend failure.
    ///
    /// When set, `addEmployee(_:)` will throw this error immediately.
    /// This enables tests to verify that:
    ///   • errors surface through `ErrorHandling`
    ///   • UI state is updated appropriately
    var stubbedError: Error?

    /// Records the input and either returns normally or throws a stubbed error.
    ///
    /// - Parameter input: The employee record provided by the ViewModel.
    /// - Throws: `stubbedError` if present.
    func addEmployee(_ input: EmployeeInput) async throws {
        callCount += 1
        lastInput = input
        if let error = stubbedError { throw error }
    }
}
