//
//  FaceDetectorProtocol.swift
//
//  Abstracts the raw face-detection stage so Vision-specific logic can be
//  mocked, replaced, or upgraded independently of the rest of the pipeline.
//

import Vision
import CoreImage

/// Defines the interface for components capable of detecting faces in an image.
///
/// Implementations return the **first detected face** as a `VNFaceObservation`.
/// They are not responsible for determining whether the face is *usable* —
/// that job belongs to `FaceValidatorProtocol` and the `FaceAnalyzer`.
///
/// ### Responsibilities
/// - Run a detection pass on the provided image
/// - Return the first `VNFaceObservation` if present
///
/// ### Non-Responsibilities
/// - Quality checks (blur, lighting, bounding box size)
/// - Orientation or rotation limits
/// - Capture-quality scoring (Vision 6+)
///
/// Keeping detection simple allows:
/// - fast real-time camera processing
/// - easy mocking in unit tests
/// - swapping different Vision request types in the future
///
protocol FaceDetectorProtocol {
    /// Attempts to detect the first face in the image.
    ///
    /// - Parameter image: The CIImage frame to analyze.
    /// - Returns: A `VNFaceObservation` if a face is detected; otherwise `nil`.
    func detect(in image: CIImage) -> VNFaceObservation?
}
