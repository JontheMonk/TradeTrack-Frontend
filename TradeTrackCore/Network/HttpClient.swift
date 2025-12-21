//
//  HTTPClient.swift
//
//  A lightweight, strongly-typed networking layer for communicating with the
//  backend API. Handles request building, JSON encoding/decoding, and unified
//  AppError mapping.
//

import Foundation

/// A simple, opinionated HTTP client used throughout the app for making
/// JSON-based API requests.
///
/// This client:
/// - builds URLs safely with query parameters
/// - automatically encodes request bodies using `snake_case`
/// - decodes responses using `snake_case` → `camelCase`
/// - wraps backend responses inside `APIResponse<T>`
/// - maps all failures into domain-level `AppError`s
/// - returns typed results (`T?`) on success
///
/// It is intentionally minimal — not a full networking stack — because the
/// backend uses a consistent response envelope and modern async/await removes
/// the need for callback abstractions.
///
///
/// ### Examples
///
/// **GET request**
/// ```swift
/// let employees: [EmployeeResult]? = try await http.send("GET", path: "/employees")
/// ```
///
/// **POST request with body**
/// ```swift
/// let req = EmployeeInput(... )
/// let result: EmployeeResult? = try await http.send("POST", path: "/register", body: req)
/// ```
///
/// **Handling errors**
/// ```swift
/// do {
///     let _: Empty? = try await http.send("POST", path: "/delete", body: payload)
/// } catch {
///     errorManager.showError(error)
/// }
/// ```
///
 final class HTTPClient {
    
    private let urlBuilder: URLBuildProtocol


    /// Base API URL, e.g. `https://myserver.com/api`
    private let baseURL: URL

    /// URLSession used for all requests. Defaults to `.shared` but can be
    /// injected for UI tests or mocking.
    internal let session: URLSession

    /// JSON encoder with snake_case output for backend compatibility.
    private let encoder = JSONEncoder()

    /// JSON decoder with snake_case → camelCase conversion.
    private let decoder = JSONDecoder()

    init(baseURL: URL, session: URLSession = .shared, urlBuilder : URLBuildProtocol = RealURLBuilder()) {
        self.baseURL = baseURL
        self.session = session
        self.urlBuilder = urlBuilder

        // Backend expects snake_case keys
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Public API (No Body)

    /// Sends a request without a body, returning a decoded `Response?`.
    ///
    /// If the backend returns `{ success: true, data: null }`, the return
    /// value will be `nil` — not an error.
    func send<Response: Decodable>(
        _ method: String,
        path: String,
        query: [String: String?] = [:]
    ) async throws -> Response? {
        try await request(method, path: path, query: query, bodyData: nil)
    }

    // MARK: - Public API (Encodable Body)

    /// Sends a request with a JSON-encoded body, returning the decoded response.
    func send<RequestBody: Encodable, Response: Decodable>(
        _ method: String,
        path: String,
        query: [String: String?] = [:],
        body: RequestBody
    ) async throws -> Response? {
        let data = try encoder.encode(body)
        return try await request(method, path: path, query: query, bodyData: data)
    }

    // MARK: - Core Request Logic

    /// Internal method that performs the actual HTTP request and decoding.
    ///
    /// Converts backend response envelopes (APIResponse<T>) into:
    /// - `T?` on success,
    /// - `AppError` on backend or network failure.
    private func request<Response: Decodable>(
        _ method: String,
        path: String,
        query: [String: String?],
        bodyData: Data?
    ) async throws -> Response? {
        guard let url = urlBuilder.makeURL(
                from: baseURL,
                path: path,
                query: query
            ) else {
                throw AppError(code: .badURL)
            }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let bodyData = bodyData {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = bodyData
        }

        do {
            let (data, response) = try await session.data(for: req)

            // Ensure we got an HTTP response
            guard response is HTTPURLResponse else {
                throw AppError(code: .invalidResponse)
            }

            // Decode top-level response envelope
            let env = try decoder.decode(APIResponse<Response>.self, from: data)

            if env.success {
                return env.data
            } else {
                throw AppError(code: AppErrorCode(fromBackend: env.code ?? "UNKNOWN"))
            }

        } catch let e as DecodingError {
            throw AppError(code: .decodingFailed, underlyingError: e)

        } catch let e as URLError {
            // Handle common networking errors
            switch e.code {
            case .cancelled:
                throw CancellationError()
            case .notConnectedToInternet:
                throw AppError(code: .networkUnavailable, underlyingError: e)
            case .timedOut:
                throw AppError(code: .requestTimedOut, underlyingError: e)
            case .badURL:
                throw AppError(code: .badURL, underlyingError: e)
            default:
                throw AppError(code: .unknown, underlyingError: e)
            }

        } catch let e as AppError {
            // Already wrapped — just rethrow
            throw e

        } catch {
            throw AppError(code: .unknown, underlyingError: error)
        }
    }

}
