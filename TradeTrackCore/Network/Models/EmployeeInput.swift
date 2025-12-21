//
//  EmployeeInput.swift
//
//  DTO sent from the iOS app to the backend when registering a new employee.
//  This struct is encoded as JSON and includes both identity information and
//  the 512-dimensional face embedding produced by your recognition pipeline.
//

import Foundation

/// Payload used when creating or updating an employee record on the backend.
///
/// This model is `Codable` because it is serialized into JSON for HTTP
/// requests (e.g., `POST /employees`).
///
/// ### Fields
/// - `employeeId`: Unique identifier for the employee (badge ID, staff number, etc.)
/// - `name`: Display name to associate with the face embedding
/// - `embedding`: 512-float vector produced by the face recognition model
/// - `role`: Application-defined role/category (e.g., “employee”, “manager”)
///
/// ### Usage
/// ```swift
/// let payload = EmployeeInput(
///     employeeId: "A123",
///     name: "Jon Snider",
///     embedding: embedding.values,
///     role: "employee"
/// )
/// try await http.post("/register", payload)
/// ```
public struct EmployeeInput: Codable {
    public let employeeId: String
    public let name: String
    public let embedding: [Float]
    public let role: String

    public init(employeeId: String, name: String, embedding: [Float], role: String) {
        self.employeeId = employeeId
        self.name = name
        self.embedding = embedding
        self.role = role
    }
}
