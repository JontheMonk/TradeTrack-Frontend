//
//  ClockStatus.swift
//
//  Represents the current clock-in state for an employee.
//  Returned by the /clock/{employee_id}/status endpoint.
//

import Foundation

/// The current clock-in state for an employee.
///
/// This struct conforms to:
/// - `Decodable` so it can be parsed directly from JSON responses.
///
/// ### Fields
/// - `isClockedIn`: Whether the employee is currently clocked in.
/// - `clockInTime`: When the current shift started (nil if not clocked in).
///
/// ### Usage
///
/// let status: ClockStatus = try await timeService.getStatus(employeeId: id)
///
/// if status.isClockedIn {
///     Text("Clocked in since \(status.clockInTime!)")
/// } else {
///     Text("Not clocked in")
/// }
public struct ClockStatus: Decodable {
    public let isClockedIn: Bool
    public let clockInTime: Date?
    
    public init(isClockedIn: Bool, clockInTime: Date? = nil) {
        self.isClockedIn = isClockedIn
        self.clockInTime = clockInTime
    }
}
