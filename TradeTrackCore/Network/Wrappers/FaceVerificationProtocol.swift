public protocol FaceVerificationProtocol {
    func verifyFace(employeeId: String, embedding: FaceEmbedding) async throws
}
