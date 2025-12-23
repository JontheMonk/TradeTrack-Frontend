import Foundation
import TradeTrackCore

/// A lightweight dependency-injection container for the app.
@MainActor
struct AppContainer {

    // MARK: - Core Infrastructure
    
    let cameraManager: CameraManagerProtocol
    let faceAnalyzer: FaceAnalyzerProtocol
    let faceProcessor: FaceProcessing
    
    // MARK: - Application Services

    let registrationService: RegistrationEmbeddingServing
    let employeeAPI: EmployeeRegistrationServing
    let employeeLookupService: EmployeeLookupServing
    let faceVerificationService: FaceVerificationProtocol

    // MARK: - Initialization

    init(environment: AppMode) throws {
        // 1. Networking Configuration
        // Handled internally by the factory to avoid leaking mock implementation details.
        CoreFactory.setupMockNetworking(for: environment)

        let session: URLSession = (environment == .normal) ? .shared : .mock()
        
        // 2. Build Pipeline Components
        self.faceAnalyzer = CoreFactory.makeFaceAnalyzer()
        self.faceProcessor = try CoreFactory.makeFaceProcessor()
        
        // 3. Build Camera Manager
        // The factory handles switching between UITestCameraManager and the real one.
        self.cameraManager = CoreFactory.makeCameraManager(for: environment)

        let extractor = CoreFactory.makeRegistrationService(
            analyzer: self.faceAnalyzer,
            processor: self.faceProcessor
        )
        
        // 4. Build Application Services
        self.registrationService = RegistrationEmbeddingService(extractor: extractor)
        
        self.employeeAPI = CoreFactory.makeEmployeeAPI(session: session)
        self.employeeLookupService = CoreFactory.makeEmployeeLookupService(session: session)
        self.faceVerificationService = CoreFactory.makeFaceVerificationService(session: session)
    }
}
