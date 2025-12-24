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
            // No more lock.lock()! The actor handles isolation.
            try sequenceHandler.perform([detectionReq], on: image, orientation: orientation)
            
            guard let face = detectionReq.results?.first else { return nil }
            
            qualityReq.inputFaceObservations = [face]
            try sequenceHandler.perform([qualityReq], on: image, orientation: orientation)
            
            guard let resultFace = qualityReq.results?.first as? VNFaceObservation else {
                return (face, 0.0)
            }
            
            let score = resultFace.faceCaptureQuality ?? 0.0
            return (resultFace, score)
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
