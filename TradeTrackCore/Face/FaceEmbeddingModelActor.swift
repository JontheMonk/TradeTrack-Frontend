import CoreML

actor FaceEmbeddingModelActor: FaceEmbeddingModelProtocol {
    private let model: w600k_r50_image

    init() throws {
        let config = MLModelConfiguration()
        self.model = try w600k_r50_image(configuration: config)
    }

    /// The input is now 'w600k_r50_imageInput' which accepts a CVPixelBuffer
    func prediction(input: w600k_r50_imageInput) async throws -> w600k_r50_imageOutput {
        return try await model.prediction(input: input)
    }
}
