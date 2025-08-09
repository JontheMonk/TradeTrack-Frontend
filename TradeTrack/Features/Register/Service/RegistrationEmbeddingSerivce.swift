import Foundation
import CoreImage
import UIKit

protocol RegistrationEmbeddingServing {
    func embedding(from image: UIImage) throws -> [Float]
}

final class RegistrationEmbeddingService: RegistrationEmbeddingServing {
    private let detector = FaceDetector()
    private let processor = try! FaceProcessor()

    func embedding(from image: UIImage) throws -> [Float] {
        guard let cg = image.cgImage else { throw AppError(code: .invalidImage) }
        let ci = CIImage(cgImage: cg)
        guard let face = detector.detectFace(in: ci) else { throw AppError(code: .noFaceDetected) }
        return try processor.process(ci, face: face).values
    }
}
