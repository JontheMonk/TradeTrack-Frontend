import Foundation
import CoreImage
import Vision
import CoreVideo

class FaceValidator {

    func validate(buffer: CVPixelBuffer, face: VNFaceObservation) throws {
        guard let landmarks = face.landmarks else {
            throw AppError(code: .faceValidationMissingLandmarks)
        }

        guard let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye,
              let nose = landmarks.nose,
              landmarks.outerLips != nil else {
            throw AppError(code: .faceValidationIncompleteLandmarks)
        }

        let (roll, yaw) = estimateRollAndYaw(leftEye: leftEye, rightEye: rightEye, nose: nose)
        let brightness = estimateBrightness(from: buffer)
        let sharpness = try computeFaceQuality(from: buffer, face: face)

        guard abs(roll) <= 15 else {
            throw AppError(code: .faceValidationBadRoll)
        }

        guard abs(yaw) <= 15 else {
            throw AppError(code: .faceValidationBadYaw)
        }

        guard (0.25...0.85).contains(brightness) else {
            throw AppError(code: .faceValidationBadBrightness)
        }

        guard sharpness >= 0.2 else {
            throw AppError(code: .faceValidationBlurry)
        }
    }

    func estimateRollAndYaw(leftEye: VNFaceLandmarkRegion2D,
                            rightEye: VNFaceLandmarkRegion2D,
                            nose: VNFaceLandmarkRegion2D) -> (roll: Float, yaw: Float) {
        guard let left = leftEye.normalizedPoints.first,
              let right = rightEye.normalizedPoints.first,
              let noseX = nose.normalizedPoints.first?.x else {
            return (0, 0)
        }

        let deltaY = right.y - left.y
        let deltaX = right.x - left.x
        let rollDegrees = atan2(deltaY, deltaX) * 180 / .pi

        let eyeMidX = (left.x + right.x) / 2
        let yaw = (noseX - eyeMidX) * 100

        return (Float(rollDegrees), Float(yaw))
    }

    func estimateBrightness(from buffer: CVPixelBuffer) -> Float {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let extent = ciImage.extent

        guard let filter = CIFilter(name: "CIAreaAverage") else { return 0 }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else { return 0 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        return (Float(bitmap[0]) + Float(bitmap[1]) + Float(bitmap[2])) / (3.0 * 255.0)
    }

    func computeFaceQuality(from buffer: CVPixelBuffer, face: VNFaceObservation) throws -> Float {
        let request = VNDetectFaceCaptureQualityRequest()
        // Pick the best available revision
        if #available(iOS 17.0, *) {
            request.revision = VNDetectFaceCaptureQualityRequestRevision3
        } else {
            request.revision = VNDetectFaceCaptureQualityRequestRevision1
        }

        request.inputFaceObservations = [face]
        request.regionOfInterest = face.boundingBox

        let orientation: CGImagePropertyOrientation = .leftMirrored

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation, options: [:])
        try handler.perform([request])

        guard let obs = (request.results?.first as? VNFaceObservation) else {
            throw AppError(code: .faceValidationQualityUnavailable,
                           debugMessage: "No results from quality request.")
        }
        guard let quality = obs.faceCaptureQuality else {
            throw AppError(code: .faceValidationQualityUnavailable,
                           debugMessage: "Result present but quality == nil. bbox=\(obs.boundingBox)")
        }
        return quality
    }


}
