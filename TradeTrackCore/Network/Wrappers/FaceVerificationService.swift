import Foundation

/// Service responsible for verifying a face embedding against the backend.
///
/// This type performs **no local validation**. It assumes the provided
/// embedding is already:
/// - extracted from a high-quality face
/// - normalized
/// - suitable for backend comparison
///
/// The backend determines whether the embedding sufficiently matches
/// the target employee.
struct FaceVerificationService: FaceVerificationProtocol {

    /// HTTP client used to communicate with the verification API.
    let http: HTTPClient

    /// Sends a face embedding to the backend for identity verification.
    ///
    /// - Parameters:
    ///   - employeeId: The backend identifier of the employee being verified.
    ///   - embedding: A normalized face embedding produced by the ML pipeline.
    ///
    /// - Throws:
    ///   - `AppError.employeeNotFound`
    ///     If the provided `employeeId` does not exist in the backend.
    ///
    ///   - `AppError.faceConfidenceTooLow`
    ///     If the backend determines that the embedding does not match
    ///     the employee with sufficient confidence.
    ///
    ///   - `AppError.network`
    ///     If the request fails due to connectivity issues.
    ///
    ///   - `AppError.server`
    ///     If the backend returns an unexpected or internal error.
    ///
    ///   - Any error propagated by `HTTPClient.send(...)`
    ///     including decoding or transport failures.
    ///
    /// - Note:
    ///   A successful return indicates **identity verification succeeded**.
    ///   No value is returned because the backend response body is empty
    ///   on success.
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
