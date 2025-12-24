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
struct FaceAnalyzer: FaceAnalyzerProtocol {
    private let detector: FaceDetectorProtocol
    private let validator: FaceValidatorProtocol

    init(detector: FaceDetectorProtocol, validator: FaceValidatorProtocol) {
        self.detector = detector
        self.validator = validator
    }

    func analyze(in image: CIImage) async -> (VNFaceObservation, Float)? {
        guard let (face, quality) = await detector.detect(in: image) else {
            return nil
        }

        let isValid = validator.isValid(
            face: face,
            quality: quality
        )

        return isValid ? (face, quality) : nil
    }
    
    func reset() async {
        await self.detector.reset()
    }
}
