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

    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "face-detection")

    /// Runs a Vision face-landmark detection request and returns the first face
    /// found in the image.
    ///
    /// - Parameter image: A `CIImage` to inspect.
    /// - Returns: A `VNFaceObservation` if Vision detects at least one face,
    ///            or `nil` otherwise.
    ///
    /// This method logs Vision failures using unified logging.
    func detect(in image: CIImage) -> VNFaceObservation? {
        let request = VNDetectFaceLandmarksRequest()

        // Use the most recent revision available.
        if #available(iOS 17.0, *) {
            request.revision = VNDetectFaceLandmarksRequestRevision3
        }

        let handler = VNImageRequestHandler(ciImage: image, orientation: .up)

        do {
            try handler.perform([request])
            guard let face = request.results?.first else {
                logger.debug("No face detected")
                return nil
            }
            return face
        } catch {
            logger.error("Vision error: \(error.localizedDescription)")
            return nil
        }
    }
}
