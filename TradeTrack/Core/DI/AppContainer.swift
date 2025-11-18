struct AppContainer {
    // Core infra
    let http: HTTPClient
    let cameraManager: CameraManaging

    // Face pipeline
    let facePreprocessor: FacePreprocessor
    let faceEmbedder: FaceEmbedder
    let faceProcessor: FaceProcessor
    let faceDetector: FaceDetector
    let faceValidator: FaceValidating
    let faceAnalyzer: FaceAnalyzing

    // App services
    let registrationService: RegistrationEmbeddingServing
    let employeeAPI: EmployeeRegistrationServing
    let employeeLookupService: EmployeeLookupServing

    init(http: HTTPClient) throws {
        self.http = http
        self.cameraManager = CameraManager()

        // Face pipeline setup
        let pre  = FacePreprocessor()
        let emb  = try FaceEmbedder()
        let proc = FaceProcessor(preprocessor: pre, embedder: emb)
        let det  = FaceDetector()
        let val  = FaceValidator()
        let ana  = FaceAnalyzer(detector: det, validator: val)

        self.facePreprocessor = pre
        self.faceEmbedder     = emb
        self.faceProcessor    = proc
        self.faceDetector     = det
        self.faceValidator    = val
        self.faceAnalyzer     = ana

        self.registrationService = RegistrationEmbeddingService(detector: det, processor: proc)
        self.employeeAPI         = EmployeeRegistrationService(http: http)
        self.employeeLookupService = EmployeeLookupService(http: http)
    }
}
