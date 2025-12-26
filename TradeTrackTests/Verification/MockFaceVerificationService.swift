#if DEBUG
import Foundation
@testable import TradeTrackCore

final class MockFaceVerificationService: FaceVerificationProtocol {

    /// Number of times verification was attempted.
    private(set) var callCount = 0

    /// Captured payload from the last request.
    private(set) var lastEmployeeId: String?
    private(set) var lastEmbedding: FaceEmbedding?

    /// Error to simulate backend failure.
    var stubbedError: Error?

    func verifyFace(employeeId: String, embedding: FaceEmbedding) async throws {
        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        callCount += 1
        lastEmployeeId = employeeId
        lastEmbedding = embedding

        if let error = stubbedError {
            throw error
        }
    }
}
#endif
