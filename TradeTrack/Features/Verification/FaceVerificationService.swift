import Foundation

struct FaceVerificationService: FaceVerificationProtocol {
    let http: HTTPClient

    func verifyFace(employeeId: String, embedding: FaceEmbedding) async throws {
        let request = VerifyFaceRequest(
            employeeId: employeeId,
            embedding: embedding
        )

        let _: Empty? = try await http.send(
            "POST",
            path: "verify-face",
            body: request
        )
    }
}
