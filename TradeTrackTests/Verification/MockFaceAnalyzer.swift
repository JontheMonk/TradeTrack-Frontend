#if DEBUG
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
    
    var stubbedQuality: Float = 1.0

    func analyze(in image: CIImage) -> (VNFaceObservation, Float)? {
        callCount += 1
        
        guard let face = stubbedFace else {
            return nil
        }
        
        return (face, stubbedQuality)
    }
}
#endif

