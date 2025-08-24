import Foundation

struct AppContainer {
    // Core infra
    let http: HTTPClient

    // Face pipeline
    let facePreprocessor: FacePreprocessor
    let faceEmbedder: FaceEmbedder
    let faceProcessor: FaceProcessor
    let faceDetector: FaceDetector

    // App services
    let registrationService: RegistrationEmbeddingServing
    let employeeAPI: EmployeeRegistrationServing
    let employeeLookupService: EmployeeLookupServing

    init(http: HTTPClient) throws {
        self.http = http

        let pre  = FacePreprocessor()
        let emb  = try FaceEmbedder()
        let proc = FaceProcessor(preprocessor: pre, embedder: emb)
        let det  = FaceDetector()

        self.facePreprocessor = pre
        self.faceEmbedder     = emb
        self.faceProcessor    = proc
        self.faceDetector     = det

        self.registrationService   = RegistrationEmbeddingService(detector: det, processor: proc)
        self.employeeAPI           = EmployeeRegistrationService(http: http)
        self.employeeLookupService = EmployeeLookupService(http: http)
    }
}
