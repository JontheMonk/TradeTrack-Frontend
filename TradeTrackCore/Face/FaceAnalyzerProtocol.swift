//
//  FaceAnalyzerProtocol.swift
//
//  Abstraction for components that detect and validate a usable face within
//  a camera frame. Implementations should return only high-quality,
//  process-ready face observations.
//

import Vision
import CoreImage

/// Defines the interface for analyzing an image and determining whether it
/// contains a **usable** face for further processing (validation, embedding, etc.).
///
/// This protocol is intentionally minimal: it hides the details of detection,
/// validation, lighting checks, blur checks, rotation limits, and Vision’s
/// capture-quality scoring. Callers simply receive:
///
/// - a `VNFaceObservation` if the face is fully validated
/// - `nil` if no acceptable face is present
///
/// ### Typical usage
/// ```swift
/// if let face = analyzer.analyze(in: ciImage) {
///     // Face is detected AND passes validation
///     let embedding = try processor.process(face, in: ciImage)
/// }
/// ```
///
/// ### Why this abstraction matters
/// - Decouples camera flow from Vision-specific logic
/// - Makes the whole face pipeline mockable for tests
/// - Allows you to swap implementations (e.g., multi-face selection later)
///
public protocol FaceAnalyzerProtocol: Sendable {
    /// Attempts to detect and validate a single high-quality face in the image.
    ///
    /// - Parameter image: The CIImage frame to inspect.
    /// - Returns: A validated `VNFaceObservation`, or `nil` if no face
    ///            meets quality requirements.
    func analyze(in image: CIImage) async -> (VNFaceObservation, Float)?
    
    /// Clears the internal state of the underlying detection and validation engines.
    ///
    /// Call this when the face stream is interrupted (e.g., face lost,
    /// session restart) to ensure temporal tracking doesn't bleed
    /// between different subjects.
    func reset() async 
}
