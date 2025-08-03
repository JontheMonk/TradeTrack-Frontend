import Foundation

struct FaceRecord: Codable {
    let employee_id: String
    let name: String
    let embedding: [Double]
    let role: String
}
