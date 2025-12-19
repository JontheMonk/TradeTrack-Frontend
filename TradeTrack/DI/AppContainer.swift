import Foundation
import TradeTrackCore

/// A lightweight dependency-injection container for the app.
struct AppContainer {

    // MARK: - Core Infrastructure
    
    let cameraManager: CameraManagerProtocol
    let faceAnalzyer: FaceAnalyzerProtocol
    let faceProcessor: FaceProcessing
    
    // MARK: - Application Services

    let registrationService: FaceEmbeddingExtracting
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
        self.faceAnalzyer = CoreFactory.makeFaceAnalyzer()
        self.faceProcessor = try CoreFactory.makeFaceProcessor()
        
        // 3. Build Camera Manager
        // The factory handles switching between UITestCameraManager and the real one.
        self.cameraManager = CoreFactory.makeCameraManager(for: environment)

        // 4. Build Application Services
        self.registrationService = CoreFactory.makeRegistrationService(
            analyzer: self.faceAnalzyer,
            processor: self.faceProcessor
        )
        
        self.employeeAPI = CoreFactory.makeEmployeeAPI(session: session)
        self.employeeLookupService = CoreFactory.makeEmployeeLookupService(session: session)
        self.faceVerificationService = CoreFactory.makeFaceVerificationService(session: session)
    }
}
