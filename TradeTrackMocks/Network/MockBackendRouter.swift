import Foundation

/// Central routing layer for the mock backend used in UI tests.
///
/// `MockBackendRouter` translates an intercepted `URLRequest` into a
/// deterministic `(Data, URLResponse)` pair based on the active
/// `BackendWorld`.
///
/// Responsibilities:
/// - Resolve the logical backend endpoint from a request
/// - Select the correct JSON fixture for the current backend world
/// - Construct a successful HTTP response wrapping that fixture
///
/// Design principles:
/// - **Fail fast** on unexpected requests or missing fixtures
/// - Avoid stringly-typed routing logic
/// - Keep mock behavior explicit and predictable
///
/// This type is intentionally:
/// - stateless
/// - pure
/// - non-configurable at runtime (beyond world selection)
///
/// If something goes wrong here, the test *should* crash.
enum MockBackendRouter {

    /// Produces a request handler for a given backend world.
    ///
    /// The returned closure is intended to be installed into
    /// `MockURLProtocol` (or similar interception layer) and will be
    /// invoked for **every** network request made by the app during
    /// a UI test run.
    ///
    /// - Parameter world: The backend world selected at app launch.
    /// - Returns: A closure that maps a `URLRequest` to mock response data.
    ///
    /// - Throws: Propagates errors if request handling fails.
    ///
    /// Any request that:
    /// - does not map to a known `MockEndpoint`, or
    /// - does not have a fixture defined for the selected world
    ///
    /// will cause an intentional crash. This prevents tests from
    /// silently succeeding when the app makes unexpected network calls.
    static func handler(
        for world: BackendWorld
    ) -> (URLRequest) throws -> (Data, URLResponse) {

        return { request in
            guard let endpoint = MockEndpoint.from(request) else {
                fatalError(
                    "Unhandled endpoint: \(request.url?.path ?? "nil")"
                )
            }

            guard let fixtureName = world.fixtures[endpoint] else {
                fatalError(
                    "No fixture for endpoint \(endpoint) in world \(world)"
                )
            }

            let data = loadJSON(named: fixtureName)
            return ok(request, data)
        }
    }

    // MARK: - Response Construction

    /// Constructs a standard HTTP 200 response for a given request.
    ///
    /// - Parameters:
    ///   - request: The original intercepted request
    ///   - data: The JSON payload to return
    /// - Returns: A tuple containing the payload and an HTTP 200 response
    private static func ok(
        _ request: URLRequest,
        _ data: Data
    ) -> (Data, URLResponse) {

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return (data, response)
    }

    // MARK: - Fixture Loading

    /// Loads a JSON fixture from the TradeTrackCore bundle.
    private static func loadJSON(named name: String) -> Data {
        // This is clean, readable, and safe from shadowing
        guard let url = Bundle.tradeTrackMocks.url(forResource: name, withExtension: "json") else {
            fatalError("❌ Fixture '\(name).json' not found in TradeTrackCore.")
        }
        return try! Data(contentsOf: url)
    }
}
