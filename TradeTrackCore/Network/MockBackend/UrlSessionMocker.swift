import Foundation

extension URLSession {
    /// Creates a URLSession that uses MockURLProtocol for all requests.
    static func mock() -> URLSession {
            let config = URLSessionConfiguration.default
            config.protocolClasses = [MockURLProtocol.self]
            return URLSession(configuration: config)
        }
}
