import Foundation
import SwiftUI
import Vision

final class RegisterViewModel: ObservableObject {
    // MARK: - Form state
    @Published var employeeID = ""
    @Published var name = ""
    @Published var role = ""
    @Published var selectedImage: UIImage?
    @Published var showingImagePicker = false
    @Published var status = "Ready"

    // MARK: - Deps
    private let http: HTTPClient
    private let errorManager: ErrorManager
    private let faceDetector: FaceDetector
    private let faceProcessor: FaceProcessor

    // MARK: - Init
    init(
        http: HTTPClient,
        errorManager: ErrorManager,
        faceDetector: FaceDetector = FaceDetector(),
        faceProcessor: FaceProcessor? = nil
    ) throws {
        self.http = http
        self.errorManager = errorManager
        self.faceDetector = faceDetector
        self.faceProcessor = try faceProcessor ?? FaceProcessor()
    }

    // MARK: - Validation
    var isFormValid: Bool {
        !employeeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedImage != nil
    }

    // MARK: - Actions
    func registerEmployee() {
        guard isFormValid, let image = selectedImage, let cgImage = image.cgImage else {
            Task { @MainActor in self.status = "❌ Fill all fields and select a valid image" }
            return
        }

        let ciImage = CIImage(cgImage: cgImage)

        Task { [weak self] in
            guard let self else { return }
            do {
                // Detect a face
                guard let face = self.faceDetector.detectFace(in: ciImage) else {
                    await MainActor.run { self.status = "❌ No face detected" }
                    return
                }

                // Create embedding using the same processor as verification
                let embedding = try self.faceProcessor.process(ciImage, face: face)

                // Build your existing EmployeeInput model
                let payload = EmployeeInput(
                    employeeId: self.employeeID,
                    name: self.name,
                    embedding: embedding.values,
                    role: self.role
                )

                // Call your endpoint; HTTPClient unwraps ApiResponse.data
                let _: EmployeeResult? = try await self.http.send(
                    "POST",
                    path: "add-employee",
                    body: payload
                )

                await MainActor.run {
                    self.status = "✅ Registered \(self.name)"
                    self.clearForm()
                }
            } catch {
                await MainActor.run {
                    self.errorManager.show(error)
                    self.status = "❌ Failed to register face"
                }
            }
        }
    }

    // MARK: - Helpers
    @MainActor
    private func clearForm() {
        employeeID = ""
        name = ""
        role = ""
        selectedImage = nil
    }
}
