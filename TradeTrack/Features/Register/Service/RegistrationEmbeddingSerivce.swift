import Foundation
import UIKit
import Vision

protocol RegistrationEmbeddingServing {
    func embedding(from image: UIImage) throws -> [Float]
}

final class RegistrationEmbeddingService: RegistrationEmbeddingServing {
    private let detector = FaceDetector()
    private var processor: FaceProcessor?

    func embedding(from image: UIImage) throws -> [Float] {
        let frame = try PhotoFrameBuilder.makeFrame(from: image)

        guard let face = detector.detectFace(in: frame.image, orientation: frame.orientation) else {
            throw AppError(code: .faceValidationMissingLandmarks)
        }

        if processor == nil {
            processor = try FaceProcessor()
        }
        // processor now guaranteed
        return try processor!.process(frame, face: face).values
    }
}
