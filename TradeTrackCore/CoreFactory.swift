import Foundation
import CoreML

/// A centralized factory responsible for instantiating and configuring the core domain services,
/// infrastructure components, and machine learning pipelines.
///
/// `CoreFactory` ensures that dependencies are correctly injected and provides specialized
/// configurations for different environments (e.g., UI Testing vs. Production).
/// ### Purpose
/// This factory acts as a bridge between the framework's internal implementation
/// details and the public consumer (the App Target). By using this factory:
/// 1. Concrete classes can remain `internal` to prevent leakage.
/// 2. The App Target only depends on `public` protocols.
/// 3. Dependencies (like CoreML models) are hidden from the main app's scope
@MainActor
public struct CoreFactory {
    
    // MARK: - Private Storage
    
    /// Cached instance of the HTTP client to ensure session persistence where required.
    private static var sharedHTTPClient: HTTPClient?
    
    /// Retrieves a shared `HTTPClient`. If the session has changed, a new client is instantiated.
    /// - Parameter session: The `URLSession` to be used for networking.
    /// - Returns: A configured `HTTPClient`.
    private static func getClient(session: URLSession) -> HTTPClient {
        if let existing = sharedHTTPClient, existing.session === session {
            return existing
        }
        
        let baseURL = URL(string: "http://localhost:8000")!
        let client = HTTPClient(baseURL: baseURL, session: session)
        sharedHTTPClient = client
        return client
    }
    

    
    // MARK: - Infrastructure
    public static func makeCameraManager() -> CameraManagerProtocol {
        return CameraManager()
    }
    
    /// A computed property that determines if CoreML should be restricted to the CPU.
    /// Typically returns `true` for Simulator environments where Neural Engine/GPU
    /// acceleration for specific ML tasks may be unstable or unavailable.
    private static var shouldForceCPU: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Face Pipeline
    
    /// Orchestrates the creation of the full Face Embedding pipeline.
    /// - Throws: An error if the underlying ML Model (`w600k_r50`) fails to load.
    /// - Returns: A fully composed `FaceEmbeddingExtractor`.
    public static func makeFaceExtractor() throws -> FaceEmbeddingExtracting {
            let analyzer = makeFaceAnalyzer()
            let processor = try makeFaceProcessor()
            return FaceEmbeddingExtractor(analyzer: analyzer, processor: processor)
        }

    /// Creates a `FaceAnalyzer` which handles the initial detection and validation of faces in a frame.
    /// - Returns: A configured `FaceAnalyzerProtocol` implementation.
    public static func makeFaceAnalyzer() -> FaceAnalyzerProtocol {
        return FaceAnalyzer(
            detector: FaceDetector(usesCPUOnly: shouldForceCPU),
            validator: FaceValidator()
        )
    }
    
    /// Creates a FaceCollector actor for managing best-frame selection.
    /// - Returns: A thread-safe object conforming to `FaceCollecting`.
    public static func makeFaceCollector() -> FaceCollecting {
        return FaceCollector()
    }
    
    /// Initializes the `FaceProcessor` including the CoreML model loading.
    /// - Throws: `MLModel` initialization errors if the weights file is missing or incompatible.
    /// - Returns: An object conforming to `FaceProcessing` for image-to-vector transformation.
    public static func makeFaceProcessor() throws -> FaceProcessing {
        let preprocessor = FacePreprocessor()
        let model = try FaceEmbeddingModelActor()
        let embedder = FaceEmbedder(model: model)
        
        return FaceProcessor(
            preprocessor: preprocessor,
            embedder: embedder
        )
    }
    
    // MARK: - Application Services
    
    /// Creates a service dedicated to extracting embeddings during the employee registration flow.
    /// - Parameters:
    ///   - analyzer: The component responsible for finding faces.
    ///   - processor: The component responsible for generating feature vectors.
    /// - Returns: A `FaceEmbeddingExtracting` service.
    public static func makeRegistrationService(
        analyzer: FaceAnalyzerProtocol,
        processor: FaceProcessing
    ) -> FaceEmbeddingExtracting {
        return FaceEmbeddingExtractor(analyzer: analyzer, processor: processor)
    }
    
    /// Creates a service for registering new employees via the backend API.
    /// - Parameter session: The `URLSession` to use for network communication.
    /// - Returns: An implementation of `EmployeeRegistrationServing`.
    public static func makeEmployeeAPI(session: URLSession) -> EmployeeRegistrationServing {
        let http = getClient(session: session)
        return EmployeeRegistrationService(http: http)
    }
    
    /// Creates a service to look up existing employee records.
    /// - Parameter session: The `URLSession` to use for network communication.
    /// - Returns: An implementation of `EmployeeLookupServing`.
    public static func makeEmployeeLookupService(session: URLSession) -> EmployeeLookupServing {
        let http = getClient(session: session)
        return EmployeeLookupService(http: http)
    }
    
    /// Creates a service for verifying face embeddings against the backend database.
    /// - Parameter session: The `URLSession` to use for network communication.
    /// - Returns: An implementation of `FaceVerificationProtocol`.
    public static func makeFaceVerificationService(session: URLSession) -> FaceVerificationProtocol {
        let http = getClient(session: session)
        return FaceVerificationService(http: http)
    }
}
