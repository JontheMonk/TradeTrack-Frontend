@testable import TradeTrack

/// Convenience helper for unit tests to extract an `AppErrorCode` from any `Error`.
///
/// In tests, many APIs throw generic `Error` values, and casting to `AppError`
/// repeatedly becomes noisy.
///
/// This extension allows cleaner assertions such as:
///
/// ```swift
/// XCTAssertEqual(error.appErrorCode, .facePreprocessingFailedRender)
/// ```
///
/// If the error is not an `AppError`, the property returns `nil`, allowing tests
/// to distinguish between wrong error types and wrong error codes.
extension Error {
    /// The underlying `AppErrorCode` if `self` is an `AppError`,
    /// or `nil` if the cast fails.
    var appErrorCode: AppErrorCode? {
        (self as? AppError)?.code
    }
}
