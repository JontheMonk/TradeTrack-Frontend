import TradeTrackCore

final class MockEmployeeLookupService: EmployeeLookupServing {

    private(set) var callCount = 0
    var stubbedResults: [EmployeeResult] = []
    var stubbedError: Error?

    func search(prefix: String) async throws -> [EmployeeResult] {
        callCount += 1
        if let error = stubbedError {
            throw error
        }
        return stubbedResults
    }
}
