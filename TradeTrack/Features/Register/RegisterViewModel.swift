import Foundation
import SwiftUI
import UIKit
import Vision

@MainActor
final class RegisterViewModel: ObservableObject {
    // MARK: - Form fields
    @Published var employeeID = ""
    @Published var name = ""
    @Published var role = "employee"
    @Published var selectedImage: UIImage?

    // MARK: - UI state
    @Published var status = "Ready"
    @Published var isSubmitting = false

    // MARK: - Deps
    private let errorManager: ErrorManager
    private let face: RegistrationEmbeddingServing
    private let api: EmployeeRegistrationServing

    // MARK: - Init
    init(
        http: HTTPClient,
        errorManager: ErrorManager,
        face: RegistrationEmbeddingServing = RegistrationEmbeddingService(),
        api: EmployeeRegistrationServing? = nil
    ) {
        self.errorManager = errorManager
        self.face = face
        self.api = api ?? EmployeeRegistrationService(http: http)
    }

    // MARK: - Derived values
    private var trimmedEmployeeID: String { employeeID.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedRole: String { role.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isFormValid: Bool {
        !trimmedEmployeeID.isEmpty &&
        !trimmedName.isEmpty &&
        !trimmedRole.isEmpty &&
        selectedImage != nil
    }

    // MARK: - Actions
    func setSelectedImage(_ image: UIImage?) {
        selectedImage = image
        if image != nil { status = "Image selected" }
    }

    func registerEmployee() async {
        guard isFormValid, let image = selectedImage else {
            status = "❌ Fill all fields and select a valid image"
            return
        }
        guard !isSubmitting else { return }

        isSubmitting = true
        status = "⏳ Registering…"
        defer { isSubmitting = false }

        do {
            let embedding = try await Task(priority: .userInitiated) {
                try face.embedding(from: image)
            }.value

            let input = EmployeeInput(
                employeeId: trimmedEmployeeID,
                name: trimmedName,
                embedding: embedding,
                role: trimmedRole
            )

            try await api.addEmployee(input)

            status = "✅ Registered \(trimmedName)"
            resetForm()
        } catch is CancellationError {
            status = "⚠️ Registration cancelled"
        } catch {
            errorManager.show(error)
            status = "❌ Failed to register face"
        }
    }

    // MARK: - Helpers
    private func resetForm() {
        employeeID = ""
        name = ""
        role = "employee" // keep default consistent
        selectedImage = nil
    }
}
