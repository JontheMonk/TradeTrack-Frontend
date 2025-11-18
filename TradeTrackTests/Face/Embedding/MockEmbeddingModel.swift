final class MockEmbeddingModel: FaceEmbeddingModeling {
    var result: w600k_r50Output?
    var error: Error?

    func prediction(input: w600k_r50Input) throws -> w600k_r50Output {
        if let error { throw error }
        return result!
    }
}
