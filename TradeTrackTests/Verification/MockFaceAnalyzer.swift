import Vision
import CoreImage
@testable import TradeTrackCore


/// Simple test double for `FaceAnalyzerProtocol`.
///
/// Lets tests control:
///   • whether a face is found
///   • how many times analysis was performed
final class MockFaceAnalyzer: FaceAnalyzerProtocol {

    private(set) var callCount = 0

    /// The observation to return from `analyze(in:)`.
    /// If `nil`, the analyzer reports “no face found”.
    var stubbedFace: VNFaceObservation?

    func analyze(in image: CIImage) -> VNFaceObservation? {
        callCount += 1
        return stubbedFace
    }
}
