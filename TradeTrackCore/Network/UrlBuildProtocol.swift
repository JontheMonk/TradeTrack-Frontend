import Foundation

/// A tiny abstraction used to **decouple URL construction from HTTPClient**.
///
/// ## Why this exists
/// `URLComponents` almost never fails in practice, which made it difficult to
/// test error paths inside `HTTPClient`. In particular, testing the `.badURL`
/// branch required a way to force URL construction to fail *before* the
/// network layer was invoked.
///
/// By introducing `URLBuildProtocol`, we can:
/// - inject a `MockURLBuilder` that returns `nil` to simulate malformed URLs
/// - verify that `HTTPClient` correctly maps this into `.badURL`
/// - avoid ever touching `URLSession` or `URLProtocol` for these tests
///
/// ## Design rationale
/// This is intentionally minimal. The HTTP client shouldn't know _how_ URLs are
/// assembled — only whether it received a valid one or not. The concrete
/// implementation (`RealURLBuilder`) simply wraps `URLComponents`, while tests
/// can provide a failing builder to hit otherwise unreachable code paths.
///
/// ## Summary
/// - Production: `RealURLBuilder` performs safe, normal URL construction.
/// - Tests: `MockURLBuilder` returns `nil` to force `.badURL`.
/// - `HTTPClient` becomes fully testable without network hacks.
protocol URLBuildProtocol {
    func makeURL(from base: URL, path: String, query: [String: String?]) -> URL?
}
