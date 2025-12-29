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
        #if DEBUG
        // 1. Networking Configuration
        CoreFactory.setupMockNetworking(for: environment)
        #endif
        
        let session: URLSession
        #if DEBUG
        session = (environment == .normal) ? .shared : .mock()
        #else
        session = .shared
        #endif
        
        // Build Pipeline Components
        self.faceAnalyzer = CoreFactory.makeFaceAnalyzer()
        self.faceCollector = CoreFactory.makeFaceCollector()
        self.faceProcessor = try CoreFactory.makeFaceProcessor()
        
        #if DEBUG
        if environment == .uiTest {
            self.cameraManager = CoreFactory.makeUITestCameraManager()
        } else {
            self.cameraManager = CoreFactory.makeCameraManager()
        }
        #else
        self.cameraManager = CoreFactory.makeCameraManager()
        #endif

        self.registrationService = try RegistrationEmbeddingService(extractor: CoreFactory.makeFaceExtractor())
        
        self.employeeAPI = CoreFactory.makeEmployeeAPI(session: session)
        self.employeeLookupService = CoreFactory.makeEmployeeLookupService(session: session)
        self.faceVerificationService = CoreFactory.makeFaceVerificationService(session: session)
        self.timeTrackingService = CoreFactory.makeTimeTrackingService(session: session)
    }
}
