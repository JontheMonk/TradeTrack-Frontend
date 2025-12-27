//
//  APIResponse.swift
//
//  Generic response wrapper used for decoding backend API results.
//  Supports success/failure states, typed payloads, and backend error codes.
//

import Foundation

/// A generic container representing the standard response format returned
/// by the backend.
///
/// Many endpoints return JSON shaped like:
/// ```json
/// {
///   "success": true,
///   "data": { ... },
///   "code": null,
///   "message": null
/// }
/// ```
///
/// or, on error:
/// ```json
/// {
///   "success": false,
///   "data": null,
///   "code": "EMPLOYEE_NOT_FOUND",
///   "message": "No such employee"
/// }
/// ```
///
/// This type allows you to decode those responses without duplicating
/// boilerplate per endpoint.
///
/// - `T` is the expected success payload type. Use `Empty` when the endpoint
///   returns no data.
/// - `code` usually corresponds to a backend enum you map into `AppErrorCode`.
/// - `message` is a backend-provided error description, not always user-friendly.
///
struct APIResponse<T> {
    /// Whether the request succeeded at the backend level.
    let success: Bool

    /// The typed returned data. Will be `nil` on failure.
    let data: T?

    /// Backend's error code string (e.g., `"EMPLOYEE_NOT_FOUND"`),
    /// or `nil` when the request succeeded.
    let code: String?

    /// Human-readable message from the backend. May not be localized or
    /// user-friendly — prefer mapping backend codes into `AppErrorCode`.
    let message: String?
}

// MARK: - Conditional Conformances

/// Decodable only when the underlying payload `T` is Decodable.
/// This is what HTTPClient needs for JSON decoding.
extension APIResponse: Decodable where T: Decodable {}

/// Encodable only when the underlying payload `T` is Encodable.
/// This allows tests to generate mock JSON envelopes.
extension APIResponse: Encodable where T: Encodable {}


/// Represents an empty response body for endpoints that return no data.
///
/// Use this as the generic parameter when an API returns:
/// ```json
/// { "success": true, "data": null, ... }
/// ```
///
/// Example:
/// ```swift
/// let _: APIResponse<Empty> = try await http.post("/reset", body)
/// ```
struct Empty: Decodable {}
