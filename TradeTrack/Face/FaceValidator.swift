import Foundation
import CoreImage
import Vision
import CoreVideo

final class FaceValidator {
    // Tunables
    private let maxRollDeg: Float = 15
    private let maxYawDeg:  Float = 15
    private let minBrightness: Float = 0.25
    private let maxBrightness: Float = 0.85
    private let minQuality: Float = 0.20

    // Shared CIContext (expensive to create, so reuse)
    private static let ci = CIContext()

    func validate(frame: FrameInput, face: VNFaceObservation) throws {
        // 1) Roll / Yaw (degrees) from Vision
        guard let roll = face.roll?.floatValue else {
            throw AppError(code: .faceValidationMissingLandmarks)
        }
        guard let yaw = face.yaw?.floatValue else {
            throw AppError(code: .faceValidationMissingLandmarks)
        }

        let rollDeg = roll * 180 / .pi
        let yawDeg  = yaw  * 180 / .pi

        guard abs(rollDeg) <= maxRollDeg else {
            throw AppError(code: .faceValidationBadRoll)
        }
        guard abs(yawDeg)  <= maxYawDeg else {
            throw AppError(code: .faceValidationBadYaw)
        }

        // 2) Brightness over face ROI
        let brightness = estimateFaceBrightness(from: frame.buffer, face: face)
        guard (minBrightness...maxBrightness).contains(brightness) else {
            throw AppError(code: .faceValidationBadBrightness)
        }

        // 3) Vision capture quality (blur/noise/occlusion proxy)
        let quality = try computeFaceQuality(from: frame.buffer, face: face, orientation: frame.orientation)
        guard quality >= minQuality else {
            throw AppError(code: .faceValidationBlurry)
        }
    }

    // MARK: - Brightness

    private func estimateFaceBrightness(from buffer: CVPixelBuffer, face: VNFaceObservation) -> Float {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let roi = FaceGeometry.pixelRect(for: face, in: buffer)

        guard let f = CIFilter(name: "CIAreaAverage") else { return 0 }
        f.setValue(ciImage, forKey: kCIInputImageKey)
        f.setValue(CIVector(cgRect: roi), forKey: kCIInputExtentKey)
        guard let out = f.outputImage else { return 0 }

        var px = [UInt8](repeating: 0, count: 4)
        Self.ci.render(out,
                       toBitmap: &px,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())

        return (Float(px[0]) + Float(px[1]) + Float(px[2])) / (3 * 255.0)
    }

    // MARK: - Vision Quality

    private func computeFaceQuality(from buffer: CVPixelBuffer,
                                    face: VNFaceObservation,
                                    orientation: CGImagePropertyOrientation) throws -> Float {
        let req = VNDetectFaceCaptureQualityRequest()
        if #available(iOS 17.0, *) {
            req.revision = VNDetectFaceCaptureQualityRequestRevision3
        } else {
            req.revision = VNDetectFaceCaptureQualityRequestRevision1
        }
        req.inputFaceObservations = [face]

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation, options: [:])
        try handler.perform([req])

        guard let obs = req.results?.first as? VNFaceObservation,
              let q = obs.faceCaptureQuality else {
            throw AppError(code: .faceValidationQualityUnavailable)
        }
        return q
    }
}
