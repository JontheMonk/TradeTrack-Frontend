import Foundation
import UIKit
import Vision

protocol RegistrationEmbeddingServing {
    func embedding(from image: UIImage) throws -> [Float]
}

final class RegistrationEmbeddingService: RegistrationEmbeddingServing {
    private let detector = FaceDetector()
    private lazy var processor: FaceProcessor = try! FaceProcessor() // or inject

    func embedding(from image: UIImage) throws -> [Float] {
        // 1) Get CIImage + fix orientation once
        let ciRaw = image.cgImage.map(CIImage.init(cgImage:)) ?? (CIImage(image: image) ?? CIImage())
        let exif = CGImagePropertyOrientation(ui: image.imageOrientation)
        let ciUpright = ciRaw.oriented(forExifOrientation: Int32(exif.rawValue))

        // 2) Detect on CIImage (no pixel buffer yet)
        guard let face = detector.detectFace(in: ciUpright) else {
            throw AppError(code: .faceValidationMissingLandmarks)
        }

        return try processor.process(image: ciUpright, face: face).values
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
