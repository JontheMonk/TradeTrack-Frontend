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
    /// For tests
    private let usesCPUOnly: Bool
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")

    init(usesCPUOnly: Bool = false) {
        self.usesCPUOnly = usesCPUOnly
    }

    func detect(in image: CIImage) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()
        
        // Use the injected setting
        request.usesCPUOnly = self.usesCPUOnly

        if #available(iOS 17.0, *) {
            request.revision = VNDetectFaceLandmarksRequestRevision3
        }

        // Safely extract orientation
        let orientationKey = kCGImagePropertyOrientation as String
        let orientationRawValue = image.properties[orientationKey] as? UInt32 ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: orientationRawValue) ?? .up

        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)

        do {
            try handler.perform([request])
            return request.results?.first
        } catch {
            logger.error("Vision error: \(error.localizedDescription)")
            return nil
        }
    }
}
