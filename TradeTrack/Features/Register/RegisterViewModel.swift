import Foundation
import SwiftUI
import Vision

class RegisterViewModel: ObservableObject {
    @Published var employeeID = ""
    @Published var name = ""
    @Published var selectedImage: UIImage? = nil
    @Published var showingImagePicker = false
    @Published var status = "Ready"

    private let faceManager = try! FaceRecognitionPipeline()
    private let faceDetector = FaceDetector()

    var isFormValid: Bool {
        !employeeID.isEmpty &&
        !name.isEmpty &&
        selectedImage != nil
    }

    func registerFace() async {
        guard let image = selectedImage,
              let cgImage = image.cgImage else {
            await MainActor.run { self.status = "❌ Invalid image" }
            return
        }

        let ciImage = CIImage(cgImage: cgImage)

        guard let face = faceDetector.detectFace(in: ciImage) else {
            await MainActor.run { self.status = "❌ No face detected" }
            return
        }

        guard let pixelBuffer = faceManager.preprocessFace(from: ciImage, face: face),
              faceManager.isFaceValid(pixelBuffer: pixelBuffer, face: face),
              let embedding = faceManager.runModel(on: pixelBuffer) else {
            await MainActor.run { self.status = "❌ Failed to process face" }
            return
        }

        do {
            try await faceManager.addFace(
                employeeID: employeeID,
                name: name,
                embedding: embedding
            )
            await MainActor.run {
                self.status = "✅ Registered \(name)"
                self.clearForm()
            }
        } catch {
            await MainActor.run { self.status = "❌ Failed to register face" }
        }
    }

    private func clearForm() {
        employeeID = ""
        name = ""
        selectedImage = nil
    }
}
