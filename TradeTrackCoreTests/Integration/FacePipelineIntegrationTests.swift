import XCTest
import CoreImage
import Vision
@testable import TradeTrackCore
@testable import TradeTrackMocks


@MainActor
final class FacePipelineIntegrationTests: XCTestCase {

    private var extractor: FaceEmbeddingExtracting!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        extractor = try CoreFactory.makeFaceExtractor()
    }
    
    override func tearDown() {
        extractor = nil
        super.tearDown()
    }
    
    
    func test_extractor_producesNormalized512Vector() async throws {
        let image = loadCIImage(named: "jon_1")
        let embedding = try await extractor.embedding(from: image)

        XCTAssertEqual(embedding.values.count, 512, "Vector count must match InsightFace output.")
        
        let magnitude = calculateL2Norm(embedding.values)
        XCTAssertEqual(magnitude, 1.0, accuracy: 0.001, "Vectors must be normalized.")
    }
    
    
    func test_extractor_recognizesSamePerson_acrossDifferentImages() async throws {
        let jon1 = loadCIImage(named: "jon_1")
        let jon2 = loadCIImage(named: "jon_2")

        let embedding1 = try await extractor.embedding(from: jon1)
        let embedding2 = try await extractor.embedding(from: jon2)
        
        let similarity = cosineSimilarity(embedding1.values, embedding2.values)

        XCTAssertGreaterThan(similarity, 0.6, "Similarity (\(similarity)) is too low")
    }
    
    
    func test_extractor_returnsNil_whenChairIsProvided() async throws {
        let chairImage = loadCIImage(named: "chair")
        let result = try? await extractor.embedding(from: chairImage)

        XCTAssertNil(result, "The pipeline should return nil for a chair, not an embedding.")
    }
    

    func test_extractor_rejectsDifferentPerson() async throws {
        let jon1 = loadCIImage(named: "jon_1")
        let imposter = loadCIImage(named: "imposter")

        let embedding1 = try await extractor.embedding(from: jon1)
        let embedding2 = try await extractor.embedding(from: imposter)

        let similarity = cosineSimilarity(embedding1.values, embedding2.values)

        XCTAssertLessThan(similarity, 0.4, "Similarity (\(similarity)) is too high; model might confuse an imposter.")
    }
    
    func test_distinguishesBetweenGendersAndEthnicities() async throws {
        let athletes = ["kerr", "moi", "delap", "levi"]
        var embeddings: [String: FaceEmbedding] = [:]
        
        for name in athletes {
            let image = loadCIImage(named: name)
            embeddings[name] = try await extractor.embedding(from: image)
        }
        
        // Compare each pair
        for i in 0..<athletes.count {
            for j in (i + 1)..<athletes.count {
                let name1 = athletes[i]
                let name2 = athletes[j]
                
                let similarity = cosineSimilarity(
                    embeddings[name1]!.values,
                    embeddings[name2]!.values
                )
                
                XCTAssertLessThan(
                    similarity,
                    0.4,
                    "\(name1) vs \(name2) similarity too high: \(similarity)"
                )
            }
        }
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
        guard v1.count == v2.count else { return 0 }
        return zip(v1, v2).map(*).reduce(0, +)
    }
}
