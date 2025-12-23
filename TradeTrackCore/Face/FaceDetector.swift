import Vision
import CoreImage
import os.log

/// A lightweight wrapper around Apple's Vision framework that extracts the
/// first detected face and its capture quality from a frame.
final class FaceDetector: FaceDetectorProtocol {
    
    // MARK: - Properties
    
    private let usesCPUOnly: Bool
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")
    
    /// Reusable requests to avoid re-allocating them for every frame.
    private let detectionReq = VNDetectFaceRectanglesRequest()
    private let qualityReq = VNDetectFaceCaptureQualityRequest()
    
    private lazy var sequenceHandler: VNSequenceRequestHandler = {
        let handler = VNSequenceRequestHandler()
        if usesCPUOnly {
        }
        return handler
    }()
    
    // MARK: - Initialization
    
    init(usesCPUOnly: Bool = false) {
        self.usesCPUOnly = usesCPUOnly
        
        // Configure requests
        detectionReq.usesCPUOnly = usesCPUOnly
        qualityReq.usesCPUOnly = usesCPUOnly
        
        // Use latest revisions where available
        if #available(iOS 15.0, *) {
            detectionReq.revision = VNDetectFaceRectanglesRequestRevision3
            qualityReq.revision = VNDetectFaceCaptureQualityRequestRevision3
        }
    }
    
    // MARK: - Public API
    
    /// Performs face detection and quality assessment on the given image.
    /// - Parameter image: The `CIImage` from the camera or other source.
    /// - Returns: A tuple with the primary face observation and quality score (0.0–1.0), or nil if no face was detected.
    func detect(in image: CIImage) -> (VNFaceObservation, Float)? {
        let orientation = image.cgOrientation
        
        do {
            try sequenceHandler.perform([detectionReq], on: image, orientation: orientation)
            
            guard let face = detectionReq.results?.first else {
                return nil
            }
            
            // Step 2: Assess capture quality of the detected face
            qualityReq.inputFaceObservations = [face]
            try sequenceHandler.perform([qualityReq], on: image, orientation: orientation)
            
            qualityReq.inputFaceObservations = nil
            
            let quality = faceCaptureQuality(from: qualityReq.results?.first)
            return (face, quality)
        } catch {
            logger.error("Vision error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Helper to safely extract and clamp quality score
    private func faceCaptureQuality(from observation: VNObservation?) -> Float {
        guard let face = observation as? VNFaceObservation,
              let score = face.faceCaptureQuality else {
            return 0.0
        }
        return max(0.0, min(1.0, score))
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
