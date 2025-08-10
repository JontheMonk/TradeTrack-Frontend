import Foundation
import CoreImage
import Vision
import CoreVideo

final class FaceValidator {
    private let ci = CIContext()

    func validate(frame: FrameInput, face: VNFaceObservation) throws {
        guard let lm = face.landmarks else {
            throw AppError(code: .faceValidationMissingLandmarks)
        }
        guard lm.leftEye != nil, lm.rightEye != nil, lm.nose != nil, lm.outerLips != nil else {
            throw AppError(code: .faceValidationIncompleteLandmarks)
        }

        let (roll, yaw) = estimateRollAndYaw(from: lm)
        let brightness = estimateFaceBrightness(from: frame.buffer, face: face)
        let sharpness = try computeFaceQuality(from: frame.buffer, face: face, orientation: frame.orientation)

        guard abs(roll) <= 15 else { throw AppError(code: .faceValidationBadRoll) }
        guard abs(yaw)  <= 15 else { throw AppError(code: .faceValidationBadYaw) }
        guard (0.25...0.85).contains(brightness) else { throw AppError(code: .faceValidationBadBrightness) }
        guard sharpness >= 0.2 else { throw AppError(code: .faceValidationBlurry) }
    }

    // MARK: Metrics

    private func estimateRollAndYaw(from lm: VNFaceLandmarks2D) -> (roll: Float, yaw: Float) {
        guard let left = lm.leftEye?.normalizedPoints.first,
              let right = lm.rightEye?.normalizedPoints.first,
              let noseX = lm.nose?.normalizedPoints.first?.x else { return (0,0) }
        let rollDeg = atan2(right.y - left.y, right.x - left.x) * 180 / .pi
        let eyeMidX = (left.x + right.x) / 2
        let yaw = (noseX - eyeMidX) * 100
        return (Float(rollDeg), Float(yaw))
    }

    /// Brightness over the face ROI in the full-frame buffer (no extra crop image).
    private func estimateFaceBrightness(from buffer: CVPixelBuffer, face: VNFaceObservation) -> Float {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let roi = FaceGeometry.pixelRect(for: face, in: buffer)
        guard let f = CIFilter(name: "CIAreaAverage") else { return 0 }
        f.setValue(ciImage, forKey: kCIInputImageKey)
        f.setValue(CIVector(cgRect: roi), forKey: kCIInputExtentKey)
        guard let out = f.outputImage else { return 0 }

        var px = [UInt8](repeating: 0, count: 4)
        ci.render(out,
                  toBitmap: &px,
                  rowBytes: 4,
                  bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                  format: .RGBA8,
                  colorSpace: CGColorSpaceCreateDeviceRGB())
        return (Float(px[0]) + Float(px[1]) + Float(px[2])) / (3 * 255.0)
    }

    /// Vision quality on the full frame using the original observation + correct orientation.
    private func computeFaceQuality(from buffer: CVPixelBuffer,
                                    face: VNFaceObservation,
                                    orientation: CGImagePropertyOrientation) throws -> Float {
        let req = VNDetectFaceCaptureQualityRequest()
        if #available(iOS 17.0, *) { req.revision = VNDetectFaceCaptureQualityRequestRevision3 }
        else { req.revision = VNDetectFaceCaptureQualityRequestRevision1 }
        req.inputFaceObservations = [face] // ROI comes from the observation

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation, options: [:])
        try handler.perform([req])

        guard let obs = req.results?.first as? VNFaceObservation,
              let q = obs.faceCaptureQuality else {
            throw AppError(code: .faceValidationQualityUnavailable)
        }
        return q
    }
}
