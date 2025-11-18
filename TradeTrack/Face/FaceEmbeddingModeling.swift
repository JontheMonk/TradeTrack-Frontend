import CoreML

protocol FaceEmbeddingModeling {
    func prediction(input: w600k_r50Input) throws -> w600k_r50Output
}

extension w600k_r50: FaceEmbeddingModeling {}
