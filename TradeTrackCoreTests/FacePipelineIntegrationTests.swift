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

    private func calculateL2Norm(_ vector: [Float]) -> Float {
        let squaredSum = vector.reduce(0) { $0 + ($1 * $1) }
        return sqrt(squaredSum)
    }
}

// MARK: - Private Helpers

private extension FacePipelineIntegrationTests {
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
}
