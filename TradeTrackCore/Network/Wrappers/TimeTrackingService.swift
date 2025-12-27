//
//  TimeTrackingService.swift
//
//  Production implementation of TimeTrackingServing backed by HTTPClient.
//

/// Production implementation of `TimeTrackingServing` backed by `HTTPClient`.
///
/// Handles the clock-in, clock-out, and status API calls, unwrapping
/// the server's `APIResponse` envelope.
struct TimeTrackingService: TimeTrackingServing {
    let http: HTTPClient
    
    func clockIn(employeeId: String) async throws -> ClockStatus {
        guard let status: ClockStatus = try await http.send(
            "POST",
            path: APIPaths.clockIn(employeeId: employeeId)
        ) else {
            throw AppError(code: .invalidResponse)
        }
        return status
    }
    
    func clockOut(employeeId: String) async throws -> ClockStatus {
        guard let status: ClockStatus = try await http.send(
            "POST",
            path: APIPaths.clockOut(employeeId: employeeId)
        ) else {
            throw AppError(code: .invalidResponse)
        }
        return status
    }
    
    func getStatus(employeeId: String) async throws -> ClockStatus {
        guard let status: ClockStatus = try await http.send(
            "GET",
            path: APIPaths.clockStatus(employeeId: employeeId)
        ) else {
            throw AppError(code: .invalidResponse)
        }
        return status
    }
}
