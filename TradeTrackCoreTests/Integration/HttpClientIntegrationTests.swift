//
//  HTTPClientIntegrationTests.swift
//
//  Integration tests for HTTPClient against the real backend.
//
//  These tests intentionally bypass mocks and exercise the full
//  HTTP + JSON + APIResponse<T> contract.
//
//  They validate that:
//   • requests are encoded correctly
//   • response envelopes are decoded correctly
//   • success with `data: null` maps to `nil`
//   • backend error codes are surfaced as AppError
//
//  @integration
//  ⚠️ Requires backend running locally at http://localhost:8000
//   - database populated with test fixtures
//

import XCTest
@testable import TradeTrackCore

final class HTTPClientIntegrationTests: XCTestCase {

    // MARK: - Setup -----------------------------------------------------------

    private var client: HTTPClient!

    override func setUp() {
        super.setUp()

        let bundle = Bundle.tradeTrackCoreTests
        
        guard let urlString = bundle.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            XCTFail("BASE_URL missing from CoreTests Info.plist")
            return
        }

        guard let url = URL(string: urlString) else {
            XCTFail("Invalid BASE_URL: \(urlString)")
            return
        }

        client = HTTPClient(baseURL: url, session: .shared)
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    // MARK: - Health ------------------------------------------------------------

    /// Verifies that the backend is running and reachable.
    func test_healthEndpoint_returnsSuccess() async throws {
        let res: Empty? = try await client.send(
            "GET",
            path: "/health"
        )

        // success == true, data == null → res == nil
        XCTAssertNil(res)
    }

    // MARK: - Verify Face (Happy Path) ---------------------------------------

    /// Verifies that POST /employees/verify:
    ///  - accepts a properly encoded VerifyFaceRequest
    ///  - returns `{ success: true, data: null }`
    ///  - maps `data: null` to a `nil` return value
    ///
    /// The endpoint performs verification as a side effect and does
    /// NOT return match details or scores.
    func test_verifyEndpoint_happyPath_returnsSuccessWithNoData() async throws {
        let service = FaceVerificationService(http: client)
        let validEmbedding = [Float](repeating: 0.1, count: 512)

        try await service.verifyFace(
            employeeId: "test_user",
            embedding: FaceEmbedding(validEmbedding)
        )
    }

    // MARK: - Verify Face (Failure Path) -------------------------------------

    /// Verifies that POST /employees/verify:
    ///  - returns `{ success: false, code: EMPLOYEE_NOT_FOUND }`
    ///  - is decoded correctly
    ///  - surfaces the backend error as AppError.employeeNotFound
    func test_verifyEndpoint_unknownEmployee_throwsEmployeeNotFound() async {
        let service = FaceVerificationService(http: client)
        let validEmbedding = [Float](repeating: 0.1, count: 512)

        do {
            try await service.verifyFace(
                employeeId: "does_not_exsit",
                embedding: FaceEmbedding(validEmbedding)
            )
            XCTFail("Expected backend error to be thrown")
        } catch {
            XCTAssertEqual(error.appErrorCode, .employeeNotFound)
        }
    }
    
    // MARK: - Employee Search -------------------------------------------------

    /// Verifies that GET /employees/search?prefix=test:
    ///  - sends the prefix as a query parameter
    ///  - decodes a successful list of EmployeeResult
    ///  - specifically finds the "test_user" fixture
    func test_searchEmployees_withValidPrefix_returnsTestUser() async throws {
        // 1. Arrange: Use the production service
        let service = EmployeeLookupService(http: client)
        let searchPrefix = "test"

        // 2. Act: Perform the search
        let results = try await service.search(prefix: searchPrefix)

        // 3. Assert: Verify the contract and data
        XCTAssertFalse(results.isEmpty, "Search should return results for prefix 'test'")
        
        let hasTestUser = results.contains { $0.employeeId == "test_user" }
        XCTAssertTrue(hasTestUser, "Results should contain the fixture 'test_user'")
    }
}
