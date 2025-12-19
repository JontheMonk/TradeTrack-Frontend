//
//  FaceEmbedding.swift
//
//  Represents a normalized embedding produced by the face recognition model.
//  Ensures all embeddings follow the same L2-normalization invariant, making
//  cosine similarity comparisons valid and consistent across the app.
//

import Foundation

/// A normalized 512-dimensional face embedding used for identity comparison.
///
/// The embedding is stored as an array of `Float` values that have been
/// **L2-normalized**, meaning their Euclidean norm is approximately `1.0`.
/// This is the standard representation expected by cosine-similarity-based
/// facial recognition systems (including InsightFace).
///
/// ### Why normalization matters
/// - Makes cosine similarity equivalent to dot product.
/// - Ensures embeddings from different lighting, angles, or sessions remain
///   comparable.
/// - Guarantees consistent numeric stability throughout your pipeline.
///
/// ### Initialization
/// The initializer accepts a raw (unnormalized) vector and normalizes it
/// automatically unless the norm is zero (e.g., a model failure), in which
/// case the raw vector is preserved.
///
/// ### Example
/// ```swift
/// let rawVector: [Float] = … // from ML model
/// let embedding = FaceEmbedding(rawVector)
///
/// // Values will now sum to ~1.0 under L2 norm
/// print(embedding.values)
/// ```
///
public struct FaceEmbedding {

    /// Invariant: `values` is L2-normalized (`||values|| ≈ 1`),
    /// unless the input vector was all zeros.
    let values: [Float]

    /// Creates a new embedding by L2-normalizing the input vector.
    ///
    /// If the input vector has a norm of zero (rare, but possible in corrupted
    /// or invalid model output), normalization is skipped and the raw values
    /// are preserved to avoid division by zero.
    init(_ raw: [Float]) {
        let sumsq = raw.reduce(Float(0)) { $0 + $1 * $1 }
        let norm = sqrt(sumsq)

        self.values = norm > 0
            ? raw.map { $0 / norm }
            : raw
    }
}
