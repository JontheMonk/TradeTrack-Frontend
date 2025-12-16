//
//  AppContainer.swift
//
//  Central dependency container for the entire app.
//
//  `AppContainer` wires together all core subsystems — camera pipeline,
//  face-processing pipeline, HTTP layer, and application services.
//
//  In addition, it is responsible for selecting the correct backend
//  execution environment (real backend vs. simulated backend world)
//  at app launch.
//
//  This acts as a single, predictable place where long-lived objects
//  are constructed, making the app easier to reason about and
//  dramatically simplifying testing.
//
//  The container does not own UI state or business logic; it only
//  constructs infrastructure and services.
//

import CoreML

/// A lightweight dependency-injection container for the app.
///
/// `AppContainer` constructs and stores:
/// - core infrastructure (HTTP client, camera manager)
/// - the entire face analysis and embedding pipeline
/// - registration, lookup, and verification services
///
/// ### Backend environments
/// At initialization time, the container selects how backend requests
/// should be handled based on the provided `AppMode`:
///
/// - `.normal`:
///   - Uses a real `URLSession`
///   - Sends requests to the actual backend
///
/// - `.uiTest`:
///   - Installs a mock URL protocol
///   - Routes all network requests through a deterministic
///     `BackendWorld` selected via launch arguments
///
/// This ensures UI tests:
/// - are fully deterministic
/// - never depend on real backend state
/// - fail loudly on unexpected network calls
///
/// ### Design notes
/// - The backend world is chosen **once**, at app launch
/// - The world does **not** change during runtime
/// - Missing or invalid test configuration is treated as a fatal error
///
/// Nothing inside `AppContainer` is tied to SwiftUI or UIKit; it is
/// pure infrastructure setup. This makes dependencies easy to mock
/// in tests and easy to swap out in previews.
///
/// ### Usage
/// Typically, the app creates one shared instance at launch:
///
/// ```swift
/// @main
/// struct TradeTrackApp: App {
///     let container = try! AppContainer(environment: .normal)
/// }
/// ```
///
/// UI tests launch the app with:
///
/// ```text
/// -BackendWorld <world>
/// ```
///
/// to select a simulated backend universe.
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


    init(environment: AppMode) throws {

        if environment == .uiTest {
            let world = BackendWorldReader.current()
            MockURLProtocol.requestHandler =
                MockBackendRouter.handler(for: world)
        }

        // Decide session
        let session: URLSession = {
            switch environment {
            case .normal:
                return .shared
            case .uiTest:
                return .mock()
            }
        }()

        let baseURL = URL(string: "http://localhost")!
        let http = HTTPClient(baseURL: baseURL, session: session)
        self.http = http

        // Camera
        self.cameraManager = CameraManager()

        let pre = FacePreprocessor()
        let det = FaceDetector()
        let val = FaceValidator()

        let model = try w600k_r50(configuration: MLModelConfiguration())
        let emb = FaceEmbedder(model: model, preprocessor: RealPixelPreprocessor())
        let proc = FaceProcessor(preprocessor: pre, embedder: emb)
        let ana = FaceAnalyzer(detector: det, validator: val)

        self.facePreprocessor = pre
        self.faceEmbedder = emb
        self.faceProcessor = proc
        self.faceDetector = det
        self.faceValidator = val
        self.faceAnalyzer = ana

        // Services (unchanged)
        self.registrationService = RegistrationEmbeddingService(analyzer: ana, processor: proc)
        self.employeeAPI = EmployeeRegistrationService(http: http)
        self.employeeLookupService = EmployeeLookupService(http: http)
        self.faceVerificationService = FaceVerificationService(http: http)
    }

}
