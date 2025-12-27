import Foundation

/// Central source of truth for all backend endpoint paths.
/// Using a shared enum ensures that the App and the Mocks
/// are always calling the same paths.
public enum APIPaths {
    
    // MARK: - Static Paths
    
    public static let search = "/employees/search"
    public static let verify = "/employees/verify"
    public static let register = "/employees/"
    
    // MARK: - Dynamic Paths (Clock)
    
    public static func clockIn(employeeId: String) -> String {
        "/clock/\(employeeId)/in"
    }
    
    public static func clockOut(employeeId: String) -> String {
        "/clock/\(employeeId)/out"
    }
    
    public static func clockStatus(employeeId: String) -> String {
        "/clock/\(employeeId)/status"
    }
}
