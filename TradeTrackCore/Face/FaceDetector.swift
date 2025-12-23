import Vision
import CoreImage
import os.log

/// A lightweight wrapper around Apple's Vision framework that extracts the
/// first detected face and its capture quality from a frame.
final class FaceDetector: FaceDetectorProtocol {
    
    // MARK: - Properties
    private let usesCPUOnly: Bool
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")
    
    private let detectionReq = VNDetectFaceRectanglesRequest()
    private let qualityReq = VNDetectFaceCaptureQualityRequest()
    
    private var sequenceHandler = VNSequenceRequestHandler()
    
    // MARK: - Initialization
    init(usesCPUOnly: Bool = false) {
        self.usesCPUOnly = usesCPUOnly
        
        detectionReq.usesCPUOnly = usesCPUOnly
        qualityReq.usesCPUOnly = usesCPUOnly
        
        // Revision 3 is specifically optimized for capture quality.
        if #available(iOS 15.0, *) {
            detectionReq.revision = VNDetectFaceRectanglesRequestRevision3
            qualityReq.revision = VNDetectFaceCaptureQualityRequestRevision3
        }
    }
    
    // MARK: - Public API
    
    /// Analyzes a live camera frame.
    func detect(in image: CIImage) -> (VNFaceObservation, Float)? {
        let orientation = image.cgOrientation
        
        do {
            // 1. Detect the face rectangle
            try sequenceHandler.perform([detectionReq], on: image, orientation: orientation)
            
            guard let face = detectionReq.results?.first else {
                return nil
            }
            
            // 2. Map the face to the Quality Request
            qualityReq.inputFaceObservations = [face]
            
            // 3. Perform quality assessment
            try sequenceHandler.perform([qualityReq], on: image, orientation: orientation)
            
            // 4. Extract quality from the result face observation
            guard let resultFace = qualityReq.results?.first as? VNFaceObservation else {
                return (face, 0.0)
            }
            
            // We return resultFace because it contains the updated metrics
            let score = resultFace.faceCaptureQuality ?? 0.0
            return (resultFace, score)
            
        } catch {
            logger.error("Vision error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func reset() {
        sequenceHandler = VNSequenceRequestHandler()
    }
}

// MARK: - Helper Extensions

private extension CIImage {
    var cgOrientation: CGImagePropertyOrientation {
        let orientationKey = kCGImagePropertyOrientation as String
        guard let rawValue = properties[orientationKey] as? UInt32,
              let orientation = CGImagePropertyOrientation(rawValue: rawValue) else {
            return .up
        }
        return orientation
    }
}
