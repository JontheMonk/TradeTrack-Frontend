import Foundation
import TradeTrackCore

/// Logical backend endpoints recognized by the mock backend.
///
/// This enum acts as a **stable routing layer** between raw URL requests
/// and higher-level backend behavior. It prevents stringly-typed logic
/// (`"/employees"`, `"/verify"`, etc.) from spreading throughout the codebase.
///
/// Adding a new backend endpoint requires:
/// 1. Adding a new case here
/// 2. Adding a fixture mapping in `BackendWorld.fixtures`
///
/// This ensures backend behavior is explicit and testable.
enum MockEndpoint {

    /// Employee lookup endpoint (`GET /employees`).
    case employees

    /// Face verification endpoint (`POST /verify`).
    case verify

    /// Attempts to infer which backend endpoint a URL request targets.
    ///
    /// - Parameter request: The intercepted `URLRequest`
    /// - Returns: A matching `MockEndpoint`, or `nil` if the request
    ///   does not correspond to a known endpoint.
    ///
    /// Returning `nil` signals a programmer error during UI tests —
    /// the mock backend will intentionally crash rather than guess.
    static func from(_ request: URLRequest) -> MockEndpoint? {
        guard let path = request.url?.path else { return nil }

        if path == APIPaths.search {
            return .employees
        }

        if path == APIPaths.verify {
            return .verify
        }

        return nil
    }
}
