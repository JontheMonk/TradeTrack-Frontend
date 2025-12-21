import Foundation
import CoreML

public struct CoreFactory {
    
    // MARK: - Private Storage
    
    private static var sharedHTTPClient: HTTPClient?
    
    private static func getClient(session: URLSession) -> HTTPClient {
        if let existing = sharedHTTPClient, existing.session === session {
            return existing
        }
        
        let baseURL = URL(string: "http://localhost")!
        let client = HTTPClient(baseURL: baseURL, session: session)
        sharedHTTPClient = client
        return client
    }
    
    // MARK: - UI Test Support
    
    /// Configures the mock backend routing if the app is in UI test mode.
    public static func setupMockNetworking(for environment: AppMode) {
        guard environment == .uiTest else { return }
        
        // These calls are now safe because they stay inside the framework
        let world = BackendWorldReader.current()
        MockURLProtocol.requestHandler = MockBackendRouter.handler(for: world)
    }
    
    // MARK: - Infrastructure
    
    /// Returns the appropriate camera manager (Real vs Simulated) for the environment.
    public static func makeCameraManager(for environment: AppMode) -> CameraManagerProtocol {
        if environment == .uiTest {
            let world = CameraWorldReader.current()
            return UITestCameraManager(world: world)
        }
        
        return CameraManager(
            deviceProvider: RealCameraDeviceProvider(),
            session: RealCaptureSession(),
            output: RealVideoOutput(),
            inputCreator: RealDeviceInputCreator()
        )
    }
    
    /// Helper to determine if we are in an environment that requires CPU-only Vision
    private static var shouldForceCPU: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Face Pipeline
    
    public static func makeFaceExtractor() throws -> FaceEmbeddingExtracting {
            let analyzer = makeFaceAnalyzer()
            let processor = try makeFaceProcessor()
            return FaceEmbeddingExtractor(analyzer: analyzer, processor: processor)
        }


    public static func makeFaceAnalyzer() -> FaceAnalyzerProtocol {
        return FaceAnalyzer(
            detector: FaceDetector(usesCPUOnly: shouldForceCPU),
            validator: FaceValidator(),
        )
    }
    
    public static func makeFaceProcessor() throws -> FaceProcessing {
        let preprocessor = FacePreprocessor()
        let model = try w600k_r50(configuration: MLModelConfiguration())
        let embedder = FaceEmbedder(model: model, preprocessor: RealPixelPreprocessor())
        
        return FaceProcessor(
            preprocessor: preprocessor,
            embedder: embedder
        )
    }
    
    // MARK: - Application Services
    
    public static func makeRegistrationService(
        analyzer: FaceAnalyzerProtocol,
        processor: FaceProcessing
    ) -> FaceEmbeddingExtracting {
        return FaceEmbeddingExtractor(analyzer: analyzer, processor: processor)
    }
    
    public static func makeEmployeeAPI(session: URLSession) -> EmployeeRegistrationServing {
        let http = getClient(session: session)
        return EmployeeRegistrationService(http: http)
    }
    
    public static func makeEmployeeLookupService(session: URLSession) -> EmployeeLookupServing {
        let http = getClient(session: session)
        return EmployeeLookupService(http: http)
    }
    
    public static func makeFaceVerificationService(session: URLSession) -> FaceVerificationProtocol {
        let http = getClient(session: session)
        return FaceVerificationService(http: http)
    }
}
