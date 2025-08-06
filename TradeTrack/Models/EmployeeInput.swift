import Foundation

struct EmployeeInput: Codable {
    let employee_id: String
    let name: String
    let embedding: [Double]
    let role: String
}
