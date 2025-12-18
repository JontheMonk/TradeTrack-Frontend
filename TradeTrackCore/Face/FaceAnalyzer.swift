//
//  FaceAnalyzer.swift
//
//  High-level wrapper that combines face detection and face validation into a
//  single step. Produces a `VNFaceObservation` only when the face is both
//  *detectable* and *valid* according to the app’s quality requirements.
//

import Vision
import CoreImage

/// Analyzes a frame for a *usable* face by running two distinct stages:
///
/// 1. **Detection** — Using `FaceDetectorProtocol`, finds the most relevant
///    face in a `CIImage`.
/// 2. **Validation** — Uses `FaceValidatorProtocol` to reject faces that are:
///    - poorly lit
///    - too small
///    - too rotated
///    - outside the frame bounds
///    - below Vision's built-in capture-quality threshold
///
/// Returning `nil` means “no face suitable for processing,” not necessarily
/// that there is no face at all. This distinction keeps camera loops clean and
/// prevents wasteful embedding attempts.
///
/// This class is intentionally lightweight and synchronous so it can be used
/// directly from frame-processing pipelines.
final class FaceAnalyzer: FaceAnalyzerProtocol {

    /// Detects faces from the input image.
    private let detector: FaceDetectorProtocol

    /// Applies quality, geometry, and Vision capture-quality constraints.
    private let validator: FaceValidatorProtocol

    init(detector: FaceDetectorProtocol, validator: FaceValidatorProtocol) {
        self.detector = detector
        self.validator = validator
    }

    /// Attempts to detect and validate a usable face in the image.
    ///
    /// - Returns: A verified `VNFaceObservation`, or `nil` if no face meets the
    ///            required quality thresholds.
    func analyze(in image: CIImage) -> VNFaceObservation? {
        // Step 1: Detect
        guard let face = detector.detect(in: image) else {
            return nil
        }

        // Step 2: Validate geometry + brightness + blur + capture-quality score
        let isValid = validator.isValid(
            face: face,
            in: image,
            captureQualityProvider: faceCaptureQuality
        )

        return isValid ? face : nil
    }

    // MARK: - Vision Capture Quality

    /// Wrapper for Apple's Vision "capture quality" API.
    ///
    /// This produces a `Float` representing how usable the face is based on
    /// sharpness, brightness, contrast, and facial feature tracking confidence.
    ///
    /// Throws if Vision fails to compute the score.
    private func faceCaptureQuality(
        face: VNFaceObservation,
        image: CIImage
    ) throws -> Float {

        let req = VNDetectFaceCaptureQualityRequest()
        req.inputFaceObservations = [face]

        let handler = VNImageRequestHandler(ciImage: image, orientation: .up)
        try handler.perform([req])

        guard
            let obs = req.results?.first as? VNFaceObservation,
            let quality = obs.faceCaptureQuality
        else {
            throw AppError(code: .faceValidationFailed)
        }

        return quality
    }
}
