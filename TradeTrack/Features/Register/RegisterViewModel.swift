import Foundation
import SwiftUI
import UIKit
import Vision
import TradeTrackCore

/// ViewModel for the employee registration screen.
///
/// Responsibilities:
/// ------------------------------------------------
/// • Holds form fields (`employeeID`, `name`, `role`, selected image)
/// • Validates the form dynamically
/// • Converts a `UIImage` into a normalized face embedding
/// • Sends registration requests to the backend
/// • Exposes simple UI state (`status`, `isSubmitting`)
/// • Reports errors through `ErrorManager`
///
/// The view never performs ML, Vision, or networking work directly.
/// It only updates bindings and calls `registerEmployee()`.
@MainActor
final class RegisterViewModel: ObservableObject {

    // MARK: - Form fields (user input)

    /// Employee's unique ID (string, trimmed before submission).
    @Published var employeeID = ""

    /// Employee's display name.
    @Published var name = ""

    /// Employee's role (defaults to `.employee`).
    @Published var role: UserRole = .employee

    /// The selected photo used for face embedding.
    @Published var selectedImage: UIImage?


    // MARK: - UI state (derived / public)

    /// Human-readable status message used in the UI ("Ready", "Image selected"…).
    @Published var status = "Ready"

    /// Whether a registration request is currently running.
    @Published var isSubmitting = false


    // MARK: - Dependencies

    private let errorManager: ErrorHandling
    private let face: RegistrationEmbeddingServing
    private let api: EmployeeRegistrationServing


    // MARK: - Init

    /// Creates a registration ViewModel.
    ///
    /// - Parameters:
    ///   - errorManager: Centralized UI error reporter.
    ///   - face: Responsible for extracting a 512-d face embedding.
    ///   - api: Responsible for sending registration data to the backend.
    init(
        errorManager: ErrorHandling,
        face: RegistrationEmbeddingServing,
        api: EmployeeRegistrationServing
    ) {
        self.errorManager = errorManager
        self.face = face
        self.api = api
    }


    // MARK: - Derived values

    private var trimmedEmployeeID: String {
        employeeID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether *all* required fields are filled and a photo has been selected.
    var isFormValid: Bool {
        !trimmedEmployeeID.isEmpty &&
        !trimmedName.isEmpty &&
        selectedImage != nil
    }


    // MARK: - Image Handling

    /// Sets the selected registration photo.
    ///
    /// The view calls this when the user picks an image from the camera or library.
    func setSelectedImage(_ image: UIImage?) {
        selectedImage = image
        if image != nil {
            status = "Image selected"
        }
    }


    // MARK: - Core Action

    /// Registers a new employee.
    ///
    /// Workflow:
    /// ---------------------------------------------------------
    /// 1) Validate the form
    /// 2) Convert the image → upright CIImage
    /// 3) Detect + validate the face
    /// 4) Extract a 512-d embedding
    /// 5) Send a `POST /add-employee` request
    ///
    /// Errors are mapped to `AppError` and shown via `ErrorManager`.
    func registerEmployee() async {
        // Basic form and state checks.
        guard isFormValid, let image = selectedImage else {
            status = "Fill all fields and select a valid image"
            return
        }
        guard !isSubmitting else { return }

        isSubmitting = true
        status = "Registering…"
        defer { isSubmitting = false }

        do {
            // Offload the embedding computation to a Task.
            let embedding = try await Task(priority: .userInitiated) {
                try await face.embedding(from: image)
            }.value

            let input = EmployeeInput(
                employeeId: trimmedEmployeeID,
                name: trimmedName,
                embedding: embedding.values,
                role: role.label
            )

            try await api.addEmployee(input)

            status = "Registered \(trimmedName)"
            resetForm()

        } catch is CancellationError {
            status = "Registration cancelled"

        } catch {
            errorManager.showError(error)
            status = "Failed to register face"
        }
    }


    // MARK: - Helpers

    /// Clears all form fields, returning to the default state.
    private func resetForm() {
        employeeID = ""
        name = ""
        role = .employee
        selectedImage = nil
    }
}
