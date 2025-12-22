import Vision
import CoreImage
import ImageIO
import os.log

/// A lightweight wrapper around Apple's Vision framework that extracts the
/// first detected face and its capture quality from a frame.
///
/// This implementation is internal to the framework to hide Vision-specific
/// types from the App Target.
final class FaceDetector: FaceDetectorProtocol {
    
    // MARK: - Properties
    
    private let usesCPUOnly: Bool
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")
    
    /// Reusable requests to avoid the overhead of re-allocating them for every frame.
    private let detectionReq = VNDetectFaceRectanglesRequest()
    private let qualityReq = VNDetectFaceCaptureQualityRequest()
    
    // MARK: - Initialization
    
    init(usesCPUOnly: Bool = false) {
        self.usesCPUOnly = usesCPUOnly
        
        detectionReq.usesCPUOnly = usesCPUOnly
        qualityReq.usesCPUOnly = usesCPUOnly

        // Revision 3 is optimized for iOS 15+ and provides better landmark precision.
        if #available(iOS 15.0, *) {
            detectionReq.revision = VNDetectFaceRectanglesRequestRevision3
        }
    }

    // MARK: - Public API
    
    /// Performs face detection and quality assessment.
    /// - Parameter image: The `CIImage` buffer from the camera or test world.
    /// - Returns: A tuple containing the primary face observation and a quality score (0.0 to 1.0).
    func detect(in image: CIImage) -> (VNFaceObservation, Float)? {
        let handler = VNImageRequestHandler(ciImage: image, orientation: image.cgOrientation)
        
        defer {
            qualityReq.inputFaceObservations = nil
        }
        
        do {
            try handler.perform([detectionReq])
            
            guard let face = detectionReq.results?.first else {
                return nil
            }

            qualityReq.inputFaceObservations = [face]
            
            try handler.perform([qualityReq])
            
            guard let qualityFace = qualityReq.results?.first else {
                return (face, 0.0)
            }
            
            let quality = qualityFace.faceCaptureQuality ?? 0.0
            
            return (face, quality)
        } catch {
            logger.error("Vision error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Helper Extensions

private extension CIImage {
    /// Safely extracts the orientation metadata from the image properties.
    /// Defaults to `.up` if metadata is missing or invalid.
    var cgOrientation: CGImagePropertyOrientation {
        let orientationKey = kCGImagePropertyOrientation as String
        if let rawValue = properties[orientationKey] as? UInt32 {
            return CGImagePropertyOrientation(rawValue: rawValue) ?? .up
        }
        return .up
    }
}
