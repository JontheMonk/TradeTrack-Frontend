import UIKit
import Vision
import CoreImage

protocol RegistrationEmbeddingServing {
    func embedding(from image: UIImage) throws -> FaceEmbedding
}

final class RegistrationEmbeddingService: RegistrationEmbeddingServing {
    private let detector: FaceDetector
    private let processor: FaceProcessor

    // Designated: pure DI
    init(detector: FaceDetector, processor: FaceProcessor) {
        self.detector = detector
        self.processor = processor
    }

    // Convenience: build defaults (throws)
    convenience init() throws {
        try self.init(detector: FaceDetector(),
                      processor: FaceProcessor())
    }

    func embedding(from image: UIImage) throws -> FaceEmbedding {
        let ciUpright = try Self.makeUprightCIImage(from: image)
        guard let face = detector.detectAndValidate(in: ciUpright) else {
            throw AppError(code: .faceValidationFailed)
        }
        return try processor.process(image: ciUpright, face: face)
    }
}

// MARK: - Private helpers
private extension RegistrationEmbeddingService {
    static func makeUprightCIImage(from image: UIImage) throws -> CIImage {
        if let cg = image.cgImage {
            let exif = CGImagePropertyOrientation(ui: image.imageOrientation)
            return CIImage(cgImage: cg).oriented(exif)
        }
        if let ci = image.ciImage {
            let exif = CGImagePropertyOrientation(ui: image.imageOrientation)
            return ci.oriented(exif)
        }
        if let ci = CIImage(image: image, options: [.applyOrientationProperty: false]) {
            let exif = CGImagePropertyOrientation(ui: image.imageOrientation)
            return ci.oriented(exif)
        }
        throw AppError(code: .imageFailedToLoad)
    }
}

private extension CGImagePropertyOrientation {
    init(ui: UIImage.Orientation) {
        switch ui {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
