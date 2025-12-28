import XCTest
import CoreImage
@testable import TradeTrackCore
@testable import TradeTrackMocks

@MainActor
final class FacePipelineIntegrationTests: XCTestCase {

    func test_extractor_producesNormalized512Vector() async throws {

        let extractor = try CoreFactory.makeFaceExtractor()
        // 4. Load and Execute
        let image = loadCIImage(named: "jon_1")
        let embedding = try await extractor.embedding(from: image)

        // 5. Verification
        XCTAssertEqual(embedding.values.count, 512, "Vector count must match InsightFace output.")
        
        let magnitude = calculateL2Norm(embedding.values)
        XCTAssertEqual(magnitude, 1.0, accuracy: 0.001, "Vectors must be normalized.")
    }
    
    func test_extractor_returnsNil_whenChairIsProvided() async throws {
        // 1. Arrange
        let extractor = try CoreFactory.makeFaceExtractor()
        let chairImage = loadCIImage(named: "chair")
        
        let result = try? await extractor.embedding(from: chairImage)

        // 3. Assert
        XCTAssertNil(result, "The pipeline should return nil for a chair, not an embedding.")
    }
    
    func test_extractor_recognizesSamePerson_acrossDifferentImages() async throws {
        let extractor = try CoreFactory.makeFaceExtractor()
        let jon1 = loadCIImage(named: "jon_1")
        let jon2 = loadCIImage(named: "jon_2")

        let embedding1 = try await extractor.embedding(from: jon1)
        let embedding2 = try await extractor.embedding(from: jon2)

        let similarity = cosineSimilarity(embedding1.values, embedding2.values)

        // Same person should have high similarity (> 0.6)
        XCTAssertGreaterThan(similarity, 0.6, "Similarity (\(similarity)) is too low; images should represent the same person.")
    }

    func test_extractor_rejectsDifferentPerson() async throws {
        let extractor = try CoreFactory.makeFaceExtractor()
        let jon1 = loadCIImage(named: "jon_1")
        let imposter = loadCIImage(named: "imposter")

        let embedding1 = try await extractor.embedding(from: jon1)
        let embedding2 = try await extractor.embedding(from: imposter)

        let similarity = cosineSimilarity(embedding1.values, embedding2.values)

        // Different people should have low similarity (< 0.4)
        XCTAssertLessThan(similarity, 0.4, "Similarity (\(similarity)) is too high; model might confuse an imposter.")
    }
}

// MARK: - Private Helpers

private extension FacePipelineIntegrationTests {
    private func calculateL2Norm(_ vector: [Float]) -> Float {
        let squaredSum = vector.reduce(0) { $0 + ($1 * $1) }
        return sqrt(squaredSum)
    }
    /// Loads a HEIC fixture from the TradeTrackCore bundle.
    func loadCIImage(named name: String) -> CIImage {
        guard let url = Bundle.tradeTrackMocks.url(forResource: name, withExtension: "HEIC") else {
            fatalError("❌ Image fixture '\(name).HEIC' not found in TradeTrackCore.")
        }
        
        guard let image = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            fatalError("❌ Failed to create CIImage from '\(name).HEIC'.")
        }
        
        return image
    }
    
    private func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        // For normalized vectors, dot product = cosine similarity
        guard v1.count == v2.count else { return 0 }
        return zip(v1, v2).map(*).reduce(0, +)
    }
}
