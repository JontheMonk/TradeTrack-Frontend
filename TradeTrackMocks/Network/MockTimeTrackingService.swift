import Foundation
import TradeTrackCore

final class MockTimeTrackingService: TimeTrackingServing {
    
    // MARK: - Call Tracking
    
    private(set) var clockInCallCount = 0
    private(set) var clockOutCallCount = 0
    private(set) var getStatusCallCount = 0
    
    // MARK: - Captured Arguments
    
    private(set) var lastClockInEmployeeId: String?
    private(set) var lastClockOutEmployeeId: String?
    private(set) var lastGetStatusEmployeeId: String?
    
    // MARK: - Stubbed Responses
    
    var stubbedClockInStatus: ClockStatus?
    var stubbedClockOutStatus: ClockStatus?
    var stubbedStatus: ClockStatus?
    
    /// Error to simulate any failure.
    var stubbedError: Error?
    
    // MARK: - Protocol Implementation
    
    func clockIn(employeeId: String) async throws -> ClockStatus {
        clockInCallCount += 1
        lastClockInEmployeeId = employeeId
        
        if let error = stubbedError { throw error }
        
        return stubbedClockInStatus ?? ClockStatus(isClockedIn: true, clockInTime: Date())
    }
    
    func clockOut(employeeId: String) async throws -> ClockStatus {
        clockOutCallCount += 1
        lastClockOutEmployeeId = employeeId
        
        if let error = stubbedError { throw error }
        
        return stubbedClockOutStatus ?? ClockStatus(isClockedIn: false, clockInTime: nil)
    }
    
    func getStatus(employeeId: String) async throws -> ClockStatus {
        getStatusCallCount += 1
        lastGetStatusEmployeeId = employeeId
        
        if let error = stubbedError { throw error }
        
        return stubbedStatus ?? ClockStatus(isClockedIn: false, clockInTime: nil)
    }
}
