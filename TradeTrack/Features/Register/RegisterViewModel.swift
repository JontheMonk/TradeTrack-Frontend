import Foundation
import SwiftUI
import Vision

@MainActor
final class RegisterViewModel: ObservableObject {
    // Form fields
    @Published var employeeID = ""
    @Published var name = ""
    @Published var role = ""
    @Published var selectedImage: UIImage?

    // UI state
    @Published var status = "Ready"
    @Published var isSubmitting = false

    // Deps
    private let errorManager: ErrorManager
    private let face: RegistrationEmbeddingServing
    private let api: EmployeeRegistrationServing

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

    // Trim + validate
    private var trimmedEmployeeID: String { employeeID.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedRole: String { role.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isFormValid: Bool {
        !trimmedEmployeeID.isEmpty &&
        !trimmedName.isEmpty &&
        !trimmedRole.isEmpty &&
        selectedImage != nil
    }

    func registerEmployee() async {
        guard isFormValid, let image = selectedImage else {
            status = "❌ Fill all fields and select a valid image"
            return
        }
        guard !isSubmitting else { return }
        isSubmitting = true
        status = "⏳ Registering…"

        do {
            // If embedding is heavy, consider offloading to a background Task.
            let embedding = try face.embedding(from: image)

            let input = EmployeeInput(
                employeeId: trimmedEmployeeID,
                name: trimmedName,
                embedding: embedding,
                role: trimmedRole
            )

            try await api.addEmployee(input)

            status = "✅ Registered \(trimmedName)"
            resetForm()
        } catch {
            errorManager.show(error)
            status = "❌ Failed to register face"
        }

        isSubmitting = false
    }

    private func resetForm() {
        employeeID = ""
        name = ""
        role = ""
        selectedImage = nil
    }
}
