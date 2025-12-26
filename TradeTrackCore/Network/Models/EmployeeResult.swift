//
//  EmployeeResult.swift
//
//  Represents an employee record returned by the backend.
//  Used for lookups, search results, and verification responses.
//

/// A lightweight, decoded employee object returned from backend APIs.
///
/// This struct conforms to:
/// - `Codable` so it can be parsed directly from JSON responses.
/// - `Identifiable` so it integrates cleanly with SwiftUI lists (using
///   `employeeId` as the stable identity).
///
/// ### Fields
/// - `employeeId`: The unique backend identifier (primary key).
/// - `name`: Display name associated with the employee.
/// - `role`: Employee role/category (e.g., “employee”, “manager”).
///
/// ### Usage
/// ```swift
/// let employees: [EmployeeResult] = try await http.get("/employees")
///
/// List(employees) { employee in
///     Text(employee.name)
/// }
/// ```
///
/// Because it’s intentionally small, this model is used only for *reading*
/// employee data. For *writing* (creating/registration), use `EmployeeInput`.
public struct EmployeeResult: Identifiable, Codable {
    public let employeeId: String
    public let name: String
    public let role: String

    /// The unique key used by SwiftUI to identify the item.
    public var id: String { employeeId }
    
    public init(employeeId: String, name: String, role: String) {
        self.employeeId = employeeId
        self.name = name
        self.role = role
    }
}
