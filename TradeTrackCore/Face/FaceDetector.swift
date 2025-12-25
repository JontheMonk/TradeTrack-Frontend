import Vision
import CoreImage
import os.log

/// An actor-based wrapper around Apple's Vision framework.
/// Actors ensure that the stateful sequenceHandler is accessed serially.
actor FaceDetector: FaceDetectorProtocol {
    private let usesCPUOnly: Bool
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")
    
    private let detectionReq = VNDetectFaceRectanglesRequest()
    private let qualityReq = VNDetectFaceCaptureQualityRequest()
    
    private var sequenceHandler = VNSequenceRequestHandler()
    
    init(usesCPUOnly: Bool = false) {
        self.usesCPUOnly = usesCPUOnly
        detectionReq.usesCPUOnly = usesCPUOnly
        qualityReq.usesCPUOnly = usesCPUOnly
        
        if #available(iOS 15.0, *) {
            detectionReq.revision = VNDetectFaceRectanglesRequestRevision3
            qualityReq.revision = VNDetectFaceCaptureQualityRequestRevision3
        }
    }
    
    func detect(in image: CIImage) async -> (VNFaceObservation, Float)? {
        let orientation = image.cgOrientation
        
        do {
            try sequenceHandler.perform([detectionReq, qualityReq], on: image, orientation: orientation)
            
            guard let detectedFace = detectionReq.results?.first else { return nil }
            
            let qualityResult = qualityReq.results?.first { $0.uuid == detectedFace.uuid }
            let score = qualityResult?.faceCaptureQuality ?? 0.0
            
            return (detectedFace, score)
        } catch {
            logger.error("Vision error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func reset() async {
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
