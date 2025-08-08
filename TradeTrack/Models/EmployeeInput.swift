import Foundation

struct EmployeeInput: Codable {
    let employeeId: String
    let name: String
    let embedding: [Double]
    let role: String
}
