import Foundation
import CoreImage
import Vision
import CoreVideo


class FaceValidator {
    
    func passesValidation(buffer: CVPixelBuffer, face: VNFaceObservation) -> Bool {
        guard let landmarks = face.landmarks,
              let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye,
              let nose = landmarks.nose,
              landmarks.outerLips != nil else { return false }

        let (roll, yaw) = estimateRollAndYaw(leftEye: leftEye, rightEye: rightEye, nose: nose)
        let brightness = estimateBrightness(from: buffer)
        let sharpness = computeFaceQuality(from: buffer, face: face)

        return abs(roll) <= 15 &&
               abs(yaw) <= 15 &&
               (0.25...0.85).contains(brightness) &&
               (sharpness ?? 0) >= 0.2
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

        let brightness = (Float(bitmap[0]) + Float(bitmap[1]) + Float(bitmap[2])) / (3.0 * 255.0)
        return brightness
    }

    func computeFaceQuality(from buffer: CVPixelBuffer, face: VNFaceObservation) -> Float? {
        let request = VNDetectFaceCaptureQualityRequest()
        request.revision = VNDetectFaceCaptureQualityRequestRevision1

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored, options: [:])
        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return nil }
            return result.faceCaptureQuality
        } catch {
            print("Quality check failed: \(error)")
            return nil
        }
    }

}
