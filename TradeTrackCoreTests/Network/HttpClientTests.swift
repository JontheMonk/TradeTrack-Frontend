import XCTest
@testable import TradeTrackCore
@testable import TradeTrackMocks

final class HTTPClientTests: XCTestCase {

    private var client: HTTPClient!
    private var baseURL: URL!

    override func setUp() {
        super.setUp()
        baseURL = URL(string: "https://example.com/api")!
        MockURLProtocol.requestHandler = nil
        client = HTTPClient(baseURL: baseURL, session: .mock())
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Success

    func test_successfulResponse_decodesData() async throws {
        struct Dummy: Codable, Equatable { let value: Int }

        let envelope = APIResponse(success: true, data: Dummy(value: 123), code: nil, message: nil)
        let data = try JSONEncoder().encode(envelope)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }

        let result: Dummy? = try await client.send("GET", path: "/dummy")
        XCTAssertEqual(result, Dummy(value: 123))
    }

    // MARK: - Backend Error

    func test_backendError_throwsAppError() async throws {
        let envelope = APIResponse<String>(success: false, data: nil, code: "EMPLOYEE_NOT_FOUND", message: "No such employee")
        let data = try JSONEncoder().encode(envelope)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        do {
            let _: String? = try await client.send("GET", path: "/dummy")
            XCTFail("Expected backend error")
        } catch let error as AppError {
            XCTAssertEqual(error.code, .employeeNotFound)
        }
    }

    // MARK: - Invalid JSON

    func test_invalidJSON_throwsDecodingFailed() async throws {
        let badData = Data("{ invalid json".utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (badData, response)
        }

        do {
            let _: String? = try await client.send("GET", path: "/dummy")
            XCTFail("Expected decoding error")
        } catch let error as AppError {
            XCTAssertEqual(error.code, .decodingFailed)
        }
    }

    // MARK: - Network Errors

    func test_networkUnavailable_throwsNetworkUnavailable() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            let _: String? = try await client.send("GET", path: "/dummy")
            XCTFail("Expected network unavailable error")
        } catch let error as AppError {
            XCTAssertEqual(error.code, .networkUnavailable)
        }
    }

    func test_timeout_throwsRequestTimedOut() async throws {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.timedOut)
        }

        do {
            let _: String? = try await client.send("GET", path: "/dummy")
            XCTFail("Expected timeout error")
        } catch let error as AppError {
            XCTAssertEqual(error.code, .requestTimedOut)
        }
    }

    // MARK: - Bad URL

    func test_badURL_throwsBadURLError() async throws {
        let badClient = HTTPClient(
            baseURL: baseURL,
            session: .mock(),
            urlBuilder: FakeFailingURLBuilder()
        )

        do {
            let _: String? = try await badClient.send("GET", path: "/test")
            XCTFail("Expected badURL error")
        } catch let error as AppError {
            XCTAssertEqual(error.code, .badURL)
        }
    }


    // MARK: - Invalid Response Type

    func test_invalidResponse_throwsInvalidResponse() async throws {
        let envelope = APIResponse(success: true, data: "OK", code: nil, message: nil)
        let data = try JSONEncoder().encode(envelope)

        MockURLProtocol.requestHandler = { request in
            let fakeResponse = URLResponse(url: request.url!,
                                           mimeType: nil,
                                           expectedContentLength: 0,
                                           textEncodingName: nil) // NOT HTTPURLResponse
            return (data, fakeResponse) // force fallback during test
        }

        do {
            let _: String? = try await client.send("GET", path: "/dummy")
            XCTFail("Expected invalidResponse error")
        } catch let error as AppError {
            XCTAssertEqual(error.code, .invalidResponse)
        }
    }


    // MARK: - Query Parameters

    func test_queryParameters_areAppendedToURL() async throws {
        struct Dummy: Codable, Equatable { let value: Int }

        let envelope = APIResponse(success: true, data: Dummy(value: 10), code: nil, message: nil)
        let data = try JSONEncoder().encode(envelope)

        MockURLProtocol.requestHandler = { request in
            let url = try XCTUnwrap(request.url)
            let comps = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

            XCTAssertEqual(comps.scheme, "https")
            XCTAssertEqual(comps.host, "example.com")
            XCTAssertEqual(comps.path, "/api/search")

            let queryItems = try XCTUnwrap(comps.queryItems)

            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "q", value: "hello")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "page", value: "2")))

            let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, resp)
        }


        _ = try await client.send(
            "GET",
            path: "/search",
            query: [
                "q": "hello",
                "page": "2"
            ]
        ) as Dummy?
    }
}
