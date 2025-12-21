import Foundation

/// The production implementation of `URLBuildProtocol`.
///
/// This type centralizes all URL construction logic used by `HTTPClient`.
/// It is intentionally simple: it converts a base URL, a path, and optional
/// query parameters into a fully-formed `URL` using `URLComponents`.
///
/// ## Why this exists
/// URL construction normally happens inline, but that makes certain failure
/// paths in `HTTPClient` nearly impossible to test — especially `.badURL`,
/// because `URLComponents` will happily percent-encode almost anything.
///
/// By moving URL construction into a dedicated type:
/// - `HTTPClient` no longer depends directly on `URLComponents`
/// - tests can inject a failing builder to simulate malformed URLs
/// - production code uses this real implementation without any changes
///
/// ## Behavior
/// - `path` is appended safely via `appendingPathComponent`
/// - `query` values are converted into `[URLQueryItem]`
/// - empty query dictionaries produce no query string
/// - returns `nil` only if `URLComponents` cannot form a valid URL
///
/// In normal usage, this builder is extremely reliable. Its main purpose is
/// to give the testing layer a seam to override.
struct RealURLBuilder: URLBuildProtocol {
    func makeURL(from base: URL, path: String, query: [String : String?]) -> URL? {
        var components = URLComponents(
            url: base.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )

        let items = query.compactMap { key, value in
            value.map { URLQueryItem(name: key, value: $0) }
        }
        components?.queryItems = items.isEmpty ? nil : items

        return components?.url
    }
}

