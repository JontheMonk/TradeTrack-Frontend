import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let code: String?
    let message: String?
}

final class HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: Public API (no body)
    func send<Response: Decodable>(
        _ method: String,
        path: String,
        query: [String: String?] = [:]
    ) async throws -> Response? {
        try await request(method, path: path, query: query, bodyData: nil) as Response?
    }

    // MARK: Public API (Encodable body)
    func send<RequestBody: Encodable, Response: Decodable>(
        _ method: String,
        path: String,
        query: [String: String?] = [:],
        body: RequestBody
    ) async throws -> Response? {
        let data = try encoder.encode(body)
        return try await request(method, path: path, query: query, bodyData: data) as Response?
    }

    // MARK: Core
    private func request<Response: Decodable>(
        _ method: String,
        path: String,
        query: [String: String?],
        bodyData: Data?
    ) async throws -> Response? {
        let url = try buildURL(path: path, query: query)

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bodyData = bodyData {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = bodyData
        }

        do {
            let (data, response) = try await session.data(for: req)
            guard response is HTTPURLResponse else {
                throw AppError(code: .invalidResponse)
            }

            let env = try decoder.decode(APIResponse<Response>.self, from: data)
            if env.success {
                return env.data
            } else {
                throw AppError(code: AppErrorCode(fromBackend: env.code ?? "UNKNOWN"))
            }

        } catch let e as DecodingError {
            throw AppError(code: .decodingFailed, underlyingError: e)
        } catch let e as URLError {
            switch e.code {
            case .notConnectedToInternet:
                throw AppError(code: .networkUnavailable, underlyingError: e)
            case .timedOut:
                throw AppError(code: .requestTimedOut, underlyingError: e)
            case .badURL:
                throw AppError(code: .badURL, underlyingError: e)
            default:
                throw AppError(code: .unknown, underlyingError: e)
            }
        } catch {
            throw AppError(code: .unknown, underlyingError: error)
        }
    }

    // MARK: Helpers
    private func buildURL(path: String, query: [String: String?]) throws -> URL {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        let items = query.compactMap { k, v in v.map { URLQueryItem(name: k, value: $0) } }
        comps?.queryItems = items.isEmpty ? nil : items
        guard let url = comps?.url else { throw AppError(code: .badURL) }
        return url
    }
}
