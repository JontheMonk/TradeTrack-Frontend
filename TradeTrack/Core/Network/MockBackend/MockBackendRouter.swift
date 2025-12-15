import Foundation

enum MockBackendRouter {

    static func handler(for world: BackendWorld) -> (URLRequest) throws -> (Data, URLResponse) {

        switch world {

        case .employeeExistsAndMatches:
            return handleEmployeeExists

        case .employeeDoesNotExist:
            return handleEmployeeMissing

        case .verificationFails:
            return handleVerificationFails
        }
    }

    // MARK: - Worlds

    private static func handleEmployeeExists(_ request: URLRequest)
    throws -> (Data, URLResponse) {

        if request.url?.path.contains("/employee/search") == true {
            let data = mockJSON("employee_search_success")
            return ok(request, data)
        }

        if request.url?.path.contains("/verify") == true {
            let data = mockJSON("verification_success")
            return ok(request, data)
        }

        fatalError("Unhandled request: \(request)")
    }

    private static func handleEmployeeMissing(_ request: URLRequest)
    throws -> (Data, URLResponse) {

        if request.url?.path.contains("/employee/search") == true {
            let data = mockJSON("employee_search_empty")
            return ok(request, data)
        }

        fatalError("Unhandled request: \(request)")
    }

    private static func handleVerificationFails(_ request: URLRequest)
    throws -> (Data, URLResponse) {

        if request.url?.path.contains("/verify") == true {
            let data = mockJSON("verification_failed")
            return ok(request, data)
        }

        fatalError("Unhandled request: \(request)")
    }

    // MARK: - Helpers

    private static func ok(_ request: URLRequest, _ data: Data)
    -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    private static func mockJSON(_ name: String) -> Data {
        let url = Bundle.main.url(forResource: name, withExtension: "json")!
        return try! Data(contentsOf: url)
    }
}
