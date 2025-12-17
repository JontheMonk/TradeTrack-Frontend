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
@testable import TradeTrack

final class HTTPClientIntegrationTests: XCTestCase {

    // MARK: - Setup -----------------------------------------------------------

    private var client: HTTPClient!

    override func setUp() {
        super.setUp()

        client = HTTPClient(
            baseURL: URL(string: "http://localhost:8000")!,
            session: .shared
        )
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
        let req = VerifyFaceRequest(
            employeeId: "test_user",
            embedding: [Double](repeating: 0.1, count: 512)
        )

        let res: Empty? = try await client.send(
            "POST",
            path: "/employees/verify",
            body: req
        )

        // success == true, data == null → res == nil
        XCTAssertNil(res)
    }

    // MARK: - Verify Face (Failure Path) -------------------------------------

    /// Verifies that POST /employees/verify:
    ///  - returns `{ success: false, code: EMPLOYEE_NOT_FOUND }`
    ///  - is decoded correctly
    ///  - surfaces the backend error as AppError.employeeNotFound
    func test_verifyEndpoint_unknownEmployee_throwsEmployeeNotFound() async {
        let req = VerifyFaceRequest(
            employeeId: "does_not_exist",
            embedding: [Double](repeating: 0.1, count: 512)
        )

        do {
            let _: Empty? = try await client.send(
                "POST",
                path: "/employees/verify",
                body: req
            )
            XCTFail("Expected backend error to be thrown")
        } catch {
            XCTAssertEqual(error.appErrorCode, .employeeNotFound)
        }
    }
}
