struct VerifyFaceResponse: Decodable {
    let employeeId: String
    let score: Double
    let threshold: Double
}
