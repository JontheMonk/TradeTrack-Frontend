import Vision
import CoreImage


final class FaceAnalyzer: FaceAnalyzing {
    private let detector: FaceDetecting
    private let validator: FaceValidating

    init(detector: FaceDetecting, validator: FaceValidating) {
        self.detector = detector
        self.validator = validator
    }

    func analyze(in image: CIImage) -> VNFaceObservation? {
        guard let face = detector.detect(in: image) else { return nil }

        let isValid = validator.isValid(
            face: face,
            in: image,
            captureQualityProvider: faceCaptureQuality
        )

        return isValid ? face : nil
    }

    private func faceCaptureQuality(
        face: VNFaceObservation,
        image: CIImage
    ) throws -> Float {
        let req = VNDetectFaceCaptureQualityRequest()
        req.inputFaceObservations = [face]

        let handler = VNImageRequestHandler(ciImage: image, orientation: .up)
        try handler.perform([req])

        guard let obs = req.results?.first as? VNFaceObservation,
              let q = obs.faceCaptureQuality else {
            throw AppError(code: .faceValidationFailed)
        }

        return q
    }
}

