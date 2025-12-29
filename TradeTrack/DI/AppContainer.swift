import Foundation
import TradeTrackCore
#if DEBUG
import TradeTrackMocks
#endif

/// A lightweight dependency-injection container for the app.
@MainActor
struct AppContainer {

    // MARK: - Core Infrastructure
    
    let cameraManager: CameraManagerProtocol
    let faceAnalyzer: FaceAnalyzerProtocol
    let faceCollector: FaceCollecting
    let faceProcessor: FaceProcessing
    
    // MARK: - Application Services

    let registrationService: RegistrationEmbeddingServing
    let employeeAPI: EmployeeRegistrationServing
    let employeeLookupService: EmployeeLookupServing
    let faceVerificationService: FaceVerificationProtocol
    let timeTrackingService: TimeTrackingServing

    // MARK: - Initialization

    init(environment: AppMode) throws {
        // 1. Networking Configuration
        // Handled internally by the factory to avoid leaking mock implementation details.
        CoreFactory.setupMockNetworking(for: environment)

        let session: URLSession = (environment == .normal) ? .shared : .mock()
        
        // Build Pipeline Components
        self.faceAnalyzer = CoreFactory.makeFaceAnalyzer()
        self.faceCollector = CoreFactory.makeFaceCollector()
        self.faceProcessor = try CoreFactory.makeFaceProcessor()
        
        if environment == .uiTest {
            self.cameraManager = CoreFactory.makeUITestCameraManager()
        } else {
            self.cameraManager = CoreFactory.makeCameraManager()
        }

        self.registrationService = try RegistrationEmbeddingService(extractor: CoreFactory.makeFaceExtractor())
        
        self.employeeAPI = CoreFactory.makeEmployeeAPI(session: session)
        self.employeeLookupService = CoreFactory.makeEmployeeLookupService(session: session)
        self.faceVerificationService = CoreFactory.makeFaceVerificationService(session: session)
        self.timeTrackingService = CoreFactory.makeTimeTrackingService(session: session)
    }
}
