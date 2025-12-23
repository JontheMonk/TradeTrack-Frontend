import CoreML

actor FaceEmbeddingModelActor: FaceEmbeddingModelProtocol {
    private let model: w600k_r50

    init() throws {
        self.model = try w600k_r50(configuration: MLModelConfiguration())
    }

    func prediction(input: w600k_r50Input) throws -> w600k_r50Output {
        return try model.prediction(input: input)
    }
}
