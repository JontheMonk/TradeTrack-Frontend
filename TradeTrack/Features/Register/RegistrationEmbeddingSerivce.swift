import UIKit
import Vision
import CoreImage
import TradeTrackCore

/// Concrete implementation of `RegistrationEmbeddingServing`.
///
/// Depends on:
///   • `FaceAnalyzerProtocol` — finds a face and enforces validation rules
///   • `FaceProcessor` — crops → resizes → pixel-preprocesses → embeds
struct RegistrationEmbeddingService : RegistrationEmbeddingServing {

    private let extractor: FaceEmbeddingExtracting

    init(extractor: FaceEmbeddingExtracting) {
        self.extractor = extractor
    }

    func embedding(from image: UIImage) async throws -> FaceEmbedding {
        guard let ciImage = CIImage(image: image) else {
            throw AppError(code: .imageFailedToLoad)
        }
        
        return try await extractor.embedding(from: ciImage)
    }
}

