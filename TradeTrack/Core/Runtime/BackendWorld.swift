import Foundation

enum BackendWorld : String {
    case employeeExistsAndMatches
    case employeeDoesNotExist
    case verificationFails
    
    var fixtures: [MockEndpoint: String] {
        switch self {
        case .employeeExistsAndMatches:
            return [
                .employees: "employee_search_success",
                .verify: "verification_success"
            ]

        case .employeeDoesNotExist:
            return [
                .employees: "employee_search_empty"
            ]

        case .verificationFails:
            return [
                .verify: "verification_failed"
            ]
        }
    }
}

enum MockEndpoint {
    case employees
    case verify

    static func from(_ request: URLRequest) -> MockEndpoint? {
        guard let path = request.url?.path else { return nil }

        if path == "/employees" {
            return .employees
        }

        if path == "/verify" {
            return .verify
        }

        return nil
    }
}


