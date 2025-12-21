//
//  FaceDetector.swift
//
//  Performs raw face detection using Apple’s Vision framework.
//  This component is intentionally “dumb”: it detects faces but does not
//  perform any validation, quality checks, or filtering. Higher-level logic
//  (FaceAnalyzer + FaceValidator) decides whether the detected face is usable.
//

import Vision
import CoreImage
import ImageIO
import os.log

/// A lightweight wrapper around `VNDetectFaceLandmarksRequest` that extracts the
/// *first detected face* from a frame.
///
/// This class has a single responsibility: run the Vision request and return
/// a `VNFaceObservation` if one exists. It does **not**:
/// - assess lighting / sharpness
/// - verify bounding-box size
/// - check rotation or framing
/// - compute capture-quality scores
///
/// Those concerns belong to `FaceValidatorProtocol` and `FaceAnalyzerProtocol`.
///
/// ### Why the detector is kept simple
/// - Keeps face-finding fast for real-time camera pipelines
/// - Keeps the validation logic isolated (so it can be mocked/tested)
/// - Allows easy swapping for multi-face detection or future VN APIs
///
final class FaceDetector: FaceDetectorProtocol {
    // 1. All stored properties must be assigned in init
    private let usesCPUOnly: Bool
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")
    
    // MARK: - Reusable Requests
    private let detectionReq = VNDetectFaceLandmarksRequest()
    private let qualityReq = VNDetectFaceCaptureQualityRequest()
    
    init(usesCPUOnly: Bool = false) {
        self.usesCPUOnly = usesCPUOnly
        
        // Handle CPU constraint across OS versions
        if #available(iOS 17.0, *) {
            // On iOS 17+, Apple prefers letting the system manage resources.
            // If you MUST use CPU, you would set detectionReq.applicableDevices = [.cpu]
        } else {
            detectionReq.usesCPUOnly = usesCPUOnly
            qualityReq.usesCPUOnly = usesCPUOnly
        }

        // Use Revision 3 for better accuracy on newer devices
        if #available(iOS 17.0, *) {
            detectionReq.revision = VNDetectFaceLandmarksRequestRevision3
        }
    }

    func detect(in image: CIImage) -> (VNFaceObservation, Float)? {
        let orientationKey = kCGImagePropertyOrientation as String
        let orientationRawValue = image.properties[orientationKey] as? UInt32 ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: orientationRawValue) ?? .up

        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)

        do {
            try handler.perform([detectionReq, qualityReq])
            
            // This guard ensures we return a non-optional (VNFaceObservation, Float)
            guard let face = detectionReq.results?.first as? VNFaceObservation,
                  let qualityFace = qualityReq.results?.first as? VNFaceObservation,
                  let quality = qualityFace.faceCaptureQuality else {
                return nil
            }
            
            return (face, quality)
        } catch {
            logger.error("Vision error: \(error.localizedDescription)")
            return nil
        }
    }
}


