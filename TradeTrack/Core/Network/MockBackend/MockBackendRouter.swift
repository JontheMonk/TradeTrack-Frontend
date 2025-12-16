import Foundation

enum MockBackendRouter {

    static func handler(for world: BackendWorld)
    -> (URLRequest) throws -> (Data, URLResponse) {

        return { request in
            guard let endpoint = MockEndpoint.from(request) else {
                fatalError("Unhandled endpoint: \(request.url?.path ?? "nil")")
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

    // MARK: - Helpers

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

    private static func loadJSON(named name: String) -> Data {
        let url = Bundle.main.url(
            forResource: name,
            withExtension: "json"
        )!
        return try! Data(contentsOf: url)
    }
}
