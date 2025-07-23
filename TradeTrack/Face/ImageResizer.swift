import CoreImage

class ImageResizer {
    static func resize(_ image: CIImage, to size: CGSize) -> CIImage? {
        let scale = size.width / image.extent.width
        let lanczos = CIFilter(name: "CILanczosScaleTransform")!
        lanczos.setValue(image, forKey: kCIInputImageKey)
        lanczos.setValue(scale, forKey: kCIInputScaleKey)
        lanczos.setValue(1.0, forKey: kCIInputAspectRatioKey)
        return lanczos.outputImage
    }
}
