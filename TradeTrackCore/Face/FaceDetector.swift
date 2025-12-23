import Vision
import CoreImage
import os.log

/// A lightweight wrapper around Apple's Vision framework that extracts the
/// first detected face and its capture quality from a frame.
import Vision
import CoreImage
import os.log

final class FaceDetector: FaceDetectorProtocol, @unchecked Sendable {
    private let usesCPUOnly: Bool
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")
    
    // Guard these requests as they are mutated (inputFaceObservations)
    private let detectionReq = VNDetectFaceRectanglesRequest()
    private let qualityReq = VNDetectFaceCaptureQualityRequest()
    
    private let lock = NSLock()
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
    
    func detect(in image: CIImage) -> (VNFaceObservation, Float)? {
        let orientation = image.cgOrientation
        
        lock.lock()
        defer { lock.unlock() }
        
        do {
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
    
    func reset() {
        lock.lock()
        sequenceHandler = VNSequenceRequestHandler()
        lock.unlock()
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
