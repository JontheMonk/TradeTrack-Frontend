//
//  VerifyFaceRequest.swift
//
//  Request payload sent to the backend during face–identity verification.
//  Encapsulates the employee identifier and the model-produced embedding.
//

import Foundation

/// Payload sent to the backend when verifying that a face embedding
/// matches the stored identity of a specific employee.
///
/// This struct is `Codable` so it can be encoded to JSON for the
/// verification endpoint (e.g., `POST /verify_face`).
///
/// ### Fields
/// - `employeeId`: The ID of the employee we are attempting to match.
/// - `embedding`: The 512-dimensional face embedding, as `[Double]`.
///   The backend uses these values to compute cosine similarity.
///
/// ### Important
/// The embedding must already be L2-normalized. `FaceEmbedding`
/// guarantees normalization, so converting it to `[Double]` is safe.
///
/// ### Example
/// ```swift
/// let emb = try faceProcessor.generateEmbedding(from: frame)
/// let request = VerifyFaceRequest(employeeId: "A123", embedding: emb)
/// try await http.post("/verify_face", request)
/// ```
struct VerifyFaceRequest: Codable {
    let employeeId: String
    let embedding: [Double]
}

extension VerifyFaceRequest {
    /// Convenience initializer for constructing the request directly
    /// from a `FaceEmbedding` domain model.
    ///
    /// Since `FaceEmbedding.values` is already normalized and stored
    /// as `[Float]`, we simply convert each element to `Double`.
    init(employeeId: String, embedding: FaceEmbedding) {
        self.init(
            employeeId: employeeId,
            embedding: embedding.values.map(Double.init)
        )
    }
}
