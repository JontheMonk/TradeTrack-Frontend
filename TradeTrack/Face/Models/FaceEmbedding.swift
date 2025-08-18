import Foundation

struct FaceEmbedding {
    /// Invariant: `values` is L2-normalized (||v|| ≈ 1).
    let values: [Float]

    init(_ raw: [Float]) {
        let sumsq = raw.reduce(Float(0)) { $0 + $1 * $1 }
        let norm = sqrt(sumsq)
        self.values = norm > 0 ? raw.map { $0 / norm } : raw
    }
}
