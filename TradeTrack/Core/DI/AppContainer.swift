import Foundation

struct AppContainer {
    // Core infra
    let http: HTTPClient
    let errorManager: ErrorManager

    // Face pipeline (singletons for app lifetime)
    let facePreprocessor: FacePreprocessor
    let faceValidator: FaceValidator
    let faceEmbedder: FaceEmbedder
    let faceProcessor: FaceProcessor
    let faceDetector: FaceDetector

    // App services
    let registrationService: RegistrationEmbeddingServing
    let employeeAPI: EmployeeRegistrationServing
    let employeeLookupService: EmployeeLookupServing

    init(http: HTTPClient) throws {
        self.http = http
        self.errorManager = ErrorManager()

        // Build face stack once
        let pre  = FacePreprocessor()
        let val  = FaceValidator()
        let emb  = try FaceEmbedder()
        let proc = FaceProcessor(preprocessor: pre, validator: val, embedder: emb)
        let det  = FaceDetector()

        self.facePreprocessor = pre
        self.faceValidator    = val
        self.faceEmbedder     = emb
        self.faceProcessor    = proc
        self.faceDetector     = det

        // High-level services
        self.registrationService  = RegistrationEmbeddingService(detector: det, processor: proc)
        self.employeeAPI          = EmployeeRegistrationService(http: http)
        self.employeeLookupService = EmployeeLookupService(http: http) // <-- your lookup impl
    }
}
