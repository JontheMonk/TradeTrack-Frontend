import Foundation

struct EmployeeInput: Codable {
    let employeeId: String
    let name: String
    let embedding: [Float]
    let role: String
}
