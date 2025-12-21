#if DEBUG
import Foundation
@testable import TradeTrackCore

/// Test double for `ErrorHandling`.
///
/// `LookupViewModel` reports errors through an injected `ErrorHandling`
/// dependency (usually `ErrorManager` in production).
/// In unit tests, we replace the real global error banner + logger with this
/// tiny mock so that:
///
///   • no UI is shown
///   • no logging is performed
///   • tests can assert *which* error was surfaced
///
/// The mock simply captures the most recent `AppError` passed to `showError(_:)`.
/// This allows ViewModel tests to verify correct error propagation without
/// any MainActor requirements or side effects.
final class MockErrorManager: ErrorHandling {

    /// The last shown error, normalized to an `AppError`.
    ///
    /// `private(set)` prevents accidental mutation during tests while still
    /// allowing assertions such as:
    ///
    /// ```swift
    /// XCTAssertEqual(mockError.shown?.code, .networkUnavailable)
    /// ```
    private(set) var lastError: AppError?

    /// Records the provided error, converting any non-`AppError` into
    /// `.unknown` for consistency, mirroring the behavior of the real manager.
    func showError(_ error: Error) {
        lastError = (error as? AppError) ?? AppError(code: .unknown)
    }
}
#endif
