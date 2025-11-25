//
//  AppContainer.swift
//
//  Central dependency container for the entire app.
//
//  `AppContainer` wires together all core subsystems — camera pipeline,
//  face-processing pipeline, HTTP layer, and registration/lookup services.
//  This acts as a single, predictable place where objects are constructed,
//  making the app easier to reason about and dramatically simplifying testing.
//
//  The container does not own UI state or business logic; it simply builds
//  and holds the long-lived service objects used throughout the app.
//

import CoreML

/// A lightweight dependency-injection container for the app.
///
/// `AppContainer` constructs and stores:
/// - core infrastructure (HTTP client, camera manager)
/// - the entire face-analysis/embedding pipeline
/// - registration and employee-lookup services
///
/// Nothing inside `AppContainer` is tied to SwiftUI or UIKit; it is pure
/// infrastructure setup. This makes the dependencies easy to mock in tests
/// and easy to swap out in previews.
///
/// ### Usage
/// Typically, the app creates one shared instance at launch:
///
/// ```swift
/// @main
/// struct TradeTrackApp: App {
///     let container = try! AppContainer(http: RealHTTPClient())
/// }
/// ```
///
/// or injects it into SwiftUI environment objects.
struct AppContainer {

    // MARK: - Core Infrastructure

    /// The HTTP client used for all backend communication.
    let http: HTTPClient

    /// Manages camera authorization, session lifecycle, and frame delivery.
    let cameraManager: CameraManagerProtocol

    // MARK: - Face Pipeline Components

    /// Performs cropping, resizing, color space normalization, etc.
    let facePreprocessor: FacePreprocessor

    /// Generates 512-dimensional embeddings using the CoreML model.
    let faceEmbedder: FaceEmbedder

    /// High-level orchestrator combining preprocessing + embedding.
    let faceProcessor: FaceProcessor

    /// Wrapper around Vision face detection requests.
    let faceDetector: FaceDetector

    /// Validates face quality (yaw/roll/brightness/size/etc.).
    let faceValidator: FaceValidatorProtocol

    /// Performs full face analysis: detection + validation.
    let faceAnalyzer: FaceAnalyzerProtocol

    // MARK: - Application Services

    /// Handles registration-time embedding storage in the backend.
    let registrationService: RegistrationEmbeddingServing

    /// Wraps HTTP endpoints for uploading employee registrations.
    let employeeAPI: EmployeeRegistrationServing

    /// Looks up employees and retrieves stored embeddings.
    let employeeLookupService: EmployeeLookupServing
    
    /// Checks backend for face
    let faceVerificationService: FaceVerificationProtocol


    // MARK: - Init

    /// Constructs the full dependency tree.
    ///
    /// This initializer creates the entire face-recognition pipeline, loads
    /// the ML model, and sets up HTTP-based services.
    ///
    /// - Parameter http: The HTTP client used for all network calls.
    init(http: HTTPClient) throws {
        self.http = http
        self.cameraManager = CameraManager()

        // Face pipeline setup
        let pre  = FacePreprocessor()
        let det  = FaceDetector()
        let val  = FaceValidator()

        let realModel = try w600k_r50(configuration: MLModelConfiguration())
        let preprocessor = RealPixelPreprocessor()
        let emb  = FaceEmbedder(model: realModel, preprocessor: preprocessor)
        let proc = FaceProcessor(preprocessor: pre, embedder: emb)
        let ana  = FaceAnalyzer(detector: det, validator: val)

        self.facePreprocessor = pre
        self.faceEmbedder     = emb
        self.faceProcessor    = proc
        self.faceDetector     = det
        self.faceValidator    = val
        self.faceAnalyzer     = ana

        // Backend services
        self.registrationService   = RegistrationEmbeddingService(analyzer: ana, processor: proc)
        self.employeeAPI           = EmployeeRegistrationService(http: http)
        self.employeeLookupService = EmployeeLookupService(http: http)
        self.faceVerificationService = FaceVerificationService(http: http)
    }
}
