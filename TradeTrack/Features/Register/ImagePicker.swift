import SwiftUI
import UIKit

/// A lightweight SwiftUI wrapper around `UIImagePickerController`.
///
/// This view allows SwiftUI screens to present the native photo picker
/// (camera or photo library) and bind the selected `UIImage` back into
/// SwiftUI state.
///
/// Features:
///  • Supports choosing images from the photo library or camera
///  • Binds the selected image via `@Binding var image`
///  • Automatically dismisses when the user picks or cancels
///  • Uses an internal `Coordinator` to bridge UIKit delegates
///
/// Usage:
/// ```swift
/// @State private var photo: UIImage?
///
/// ImagePicker(image: $photo, sourceType: .camera)
/// ```
///
/// If `sourceType` is unavailable (e.g., camera on Simulator), it falls
/// back to `.photoLibrary` to avoid crashes.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator (UIKit Delegate Bridge)

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType =
            UIImagePickerController.isSourceTypeAvailable(sourceType)
                ? sourceType
                : .photoLibrary

        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.mediaTypes = ["public.image"]
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}
}
