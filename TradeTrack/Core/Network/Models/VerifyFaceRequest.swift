struct VerifyFaceRequest: Codable {
    let employeeId: String
    let embedding: [Double]
}

extension VerifyFaceRequest {
    init(employeeId: String, embedding: FaceEmbedding) {
        self.init(employeeId: employeeId,
                  embedding: embedding.values.map(Double.init)) // already normalized
    }
}
