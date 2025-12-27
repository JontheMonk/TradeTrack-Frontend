//
//  TimeTrackingServing.swift
//
//  Protocol defining time tracking operations.
//

/// Abstraction for time tracking operations.
///
/// Why this exists:
/// ----------------
/// View models (like `DashboardViewModel`) shouldn't know about networking,
/// URLs, HTTP verbs, or backend response formats.
/// They should depend only on **what** they need:
/// "Clock in this employee", "Get their status", etc.
///
/// This protocol makes the time tracking logic:
///   • testable (you can inject a mock service)
///   • decoupled from HTTPClient
///   • flexible if backend endpoints ever change
public protocol TimeTrackingServing {
    
    /// Clock in an employee. Creates a new time entry.
    ///
    /// - Parameter employeeId: The unique identifier of the employee.
    /// - Throws: `AppError` if already clocked in or network fails.
    func clockIn(employeeId: String) async throws -> ClockStatus
    
    /// Clock out an employee. Closes the current time entry.
    ///
    /// - Parameter employeeId: The unique identifier of the employee.
    /// - Throws: `AppError` if not clocked in or network fails.
    func clockOut(employeeId: String) async throws -> ClockStatus
    
    /// Check if an employee is currently clocked in.
    ///
    /// - Parameter employeeId: The unique identifier of the employee.
    /// - Returns: The current clock status including clock-in time if active.
    func getStatus(employeeId: String) async throws -> ClockStatus
}
