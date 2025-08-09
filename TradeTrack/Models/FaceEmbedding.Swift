import Foundation

struct FaceEmbedding {
    let values: [Float]

    var normalized: [Float] {
        let norm = sqrt(values.reduce(0) { $0 + $1 * $1 })
        return norm > 0 ? values.map { $0 / norm } : values
    }

    func toVerifyRequest(employeeId: String) -> VerifyFaceRequest {
        return VerifyFaceRequest(
            employeeId: employeeId,
            embedding: normalized.map { Double($0) }
        )
    }
}

