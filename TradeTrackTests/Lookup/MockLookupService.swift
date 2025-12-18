@testable import TradeTrackCore

final class MockEmployeeLookupService: EmployeeLookupServing {

    private(set) var callCount = 0   // observed by tests, not set by tests
    var stubbedResults: [EmployeeResult] = []  // tests control
    var stubbedError: Error?         // tests control

    func search(prefix: String) async throws -> [EmployeeResult] {
        callCount += 1
        if let error = stubbedError {
            throw error
        }
        return stubbedResults
    }
}
