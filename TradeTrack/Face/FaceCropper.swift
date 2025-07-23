import CoreImage
import Vision
import CoreVideo
import Foundation



class FaceCropper {
    static func crop(from ciImage: CIImage, using face: VNFaceObservation) -> CIImage {
        let width = ciImage.extent.width
        let height = ciImage.extent.height

        let faceRect = CGRect(
            x: face.boundingBox.origin.x * width,
            y: (1 - face.boundingBox.origin.y - face.boundingBox.height) * height,
            width: face.boundingBox.width * width,
            height: face.boundingBox.height * height
        )

        return ciImage.cropped(to: faceRect)
    }

}

