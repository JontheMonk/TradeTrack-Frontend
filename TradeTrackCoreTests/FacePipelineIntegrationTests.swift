import XCTest
import CoreImage
@testable import TradeTrackCore

final class FacePipelineIntegrationTests: XCTestCase {

    func test_extractor_producesNormalized512Vector() throws {

        let extractor = try CoreFactory.makeFaceExtractor()
        // 4. Load and Execute
        let image = loadCIImage(named: "jon_1")
        let embedding = try extractor.embedding(from: image)

        // 5. Verification
        XCTAssertEqual(embedding.values.count, 512, "Vector count must match InsightFace output.")
        
        let magnitude = calculateL2Norm(embedding.values)
        XCTAssertEqual(magnitude, 1.0, accuracy: 0.001, "Vectors must be normalized.")
    }
    
    func test_extractor_returnsNil_whenChairIsProvided() throws {
        // 1. Arrange
        let extractor = try CoreFactory.makeFaceExtractor()
        let chairImage = loadCIImage(named: "chair")
        
        let result = try? extractor.embedding(from: chairImage)

        // 3. Assert
        XCTAssertNil(result, "The pipeline should return nil for a chair, not an embedding.")
    }
    
    func test_extractor_recognizesSamePerson_acrossDifferentImages() throws {
        // 1. Arrange
        let extractor = try CoreFactory.makeFaceExtractor()
        let jon1 = loadCIImage(named: "jon_1")
        let jon2 = loadCIImage(named: "jon_2")

        // 2. Act
        let embedding1 = try extractor.embedding(from: jon1)
        let embedding2 = try extractor.embedding(from: jon2)

        // 3. Calculate Distance
        let distance = calculateEuclideanDistance(embedding1.values, embedding2.values)

        // 4. Assert
        // For normalized 512d vectors (InsightFace), a distance < 1.0 is a common match threshold.
        // 0.6 - 0.9 is typical for the same person in different lighting.
        XCTAssertLessThan(distance, 0.9, "Distance (\(distance)) is too high; images should represent the same person.")
    }
    
    func test_extractor_rejectsDifferentPerson() throws {
        // 1. Arrange
        let extractor = try CoreFactory.makeFaceExtractor()
        let jon1 = loadCIImage(named: "jon_1")
        let imposter = loadCIImage(named: "imposter")

        // 2. Act
        let embedding1 = try extractor.embedding(from: jon1)
        let embedding2 = try extractor.embedding(from: imposter)

        // 3. Calculate Distance
        let distance = calculateEuclideanDistance(embedding1.values, embedding2.values)

        // 4. Assert
        // We expect a HIGH distance for different people.
        // For normalized 512d vectors, 1.2 is a safe "minimum" distance for strangers.
        XCTAssertGreaterThan(distance, 1.2, "The distance (\(distance)) is too low. The model might be confusing an imposter for the user.")
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
        guard let url = Bundle.tradeTrackCore.url(forResource: name, withExtension: "HEIC") else {
            fatalError("❌ Image fixture '\(name).HEIC' not found in TradeTrackCore.")
        }
        
        guard let image = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            fatalError("❌ Failed to create CIImage from '\(name).HEIC'.")
        }
        
        return image
    }
    
    private func calculateEuclideanDistance(_ v1: [Float], _ v2: [Float]) -> Float {
        guard v1.count == v2.count else { return .infinity }
        let sumOfSquares = zip(v1, v2).map { pow($0 - $1, 2) }.reduce(0, +)
        return sqrt(sumOfSquares)
    }
}
