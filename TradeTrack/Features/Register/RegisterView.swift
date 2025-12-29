import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel: RegisterViewModel
    @State private var showImagePicker = false
    @FocusState private var focusedField: Field?

    enum Field {
        case employeeID
        case name
    }

    init(viewModel: RegisterViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $viewModel.selectedImage)
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.selectedImage) { _, newImage in
            if newImage != nil {
                viewModel.setSelectedImage(newImage)
            }
        }
    }

    // MARK: - Main Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerView
                formFieldsView
                imageSelectionView
                submitButtonView
                statusView
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        LinearGradient(
            colors: [Color(hex: "0f0f14"), Color(hex: "1a1a24")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .onTapGesture { hideKeyboard() }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Register Employee")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Add a new employee to the system")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Form Fields

    private var formFieldsView: some View {
        VStack(spacing: 20) {
            employeeIDField
            nameField
            rolePickerField
        }
    }

    private var employeeIDField: some View {
        FormField(
            label: "Employee ID",
            content: {
                CustomTextField(
                    placeholder: "Enter employee ID",
                    text: $viewModel.employeeID,
                    field: .employeeID,
                    focusedField: $focusedField
                )
            }
        )
    }

    private var nameField: some View {
        FormField(
            label: "Full Name",
            content: {
                CustomTextField(
                    placeholder: "Enter full name",
                    text: $viewModel.name,
                    field: .name,
                    focusedField: $focusedField
                )
            }
        )
    }

    private var rolePickerField: some View {
        FormField(
            label: "Role",
            content: {
                RolePicker(selection: $viewModel.role)
            }
        )
    }

    // MARK: - Image Selection

    private var imageSelectionView: some View {
        VStack(spacing: 16) {
            imagePickerButton
            imagePreview
        }
    }

    private var imagePickerButton: some View {
        Button {
            showImagePicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: viewModel.selectedImage == nil ? "photo.badge.plus" : "photo.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(viewModel.selectedImage == nil ? "Select Face Image" : "Change Image")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "2a5fff"), Color(hex: "1a3dcc")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color(hex: "2a5fff").opacity(0.3), radius: 8, y: 4)
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let image = viewModel.selectedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Submit Button

    private var submitButtonView: some View {
        Button {
            Task { await viewModel.registerEmployee() }
        } label: {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(viewModel.isSubmitting ? "Registering..." : "Add to Database")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(submitButtonGradient)
            .cornerRadius(16)
            .overlay(submitButtonBorder)
            .shadow(
                color: viewModel.isFormValid && !viewModel.isSubmitting
                    ? Color.green.opacity(0.4)
                    : Color.clear,
                radius: viewModel.isFormValid && !viewModel.isSubmitting ? 12 : 0,
                y: viewModel.isFormValid && !viewModel.isSubmitting ? 6 : 0
            )
        }
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isFormValid)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isSubmitting)
    }

    private var submitButtonGradient: LinearGradient {
        if viewModel.isFormValid && !viewModel.isSubmitting {
            return LinearGradient(
                colors: [Color.green, Color(hex: "0d8b3d")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "2a2a35"), Color(hex: "1a1a24")],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var submitButtonBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                viewModel.isFormValid && !viewModel.isSubmitting
                    ? Color.white.opacity(0.2)
                    : Color.gray.opacity(0.2),
                lineWidth: 1
            )
    }

    // MARK: - Status

    @ViewBuilder
    private var statusView: some View {
        if !viewModel.status.isEmpty {
            StatusBanner(message: viewModel.status)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Supporting Views

private struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            content()
        }
    }
}

private struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let field: RegisterView.Field
    @FocusState.Binding var focusedField: RegisterView.Field?

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        focusedField == field
                            ? Color(hex: "2a5fff").opacity(0.5)
                            : Color.white.opacity(0.15),
                        lineWidth: focusedField == field ? 2 : 1.5
                    )
            )
            .focused($focusedField, equals: field)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onSubmit {
                switch field {
                case .employeeID:
                    focusedField = .name
                case .name:
                    hideKeyboard()
                }
            }
    }
}

private struct StatusBanner: View {
    let message: String

    private var statusColor: Color {
        if message.contains("✅") {
            return .green
        } else if message.contains("❌") {
            return .red
        } else if message.contains("⏳") {
            return .orange
        } else {
            return .gray
        }
    }

    private var statusIcon: String {
        if message.contains("✅") {
            return "checkmark.circle.fill"
        } else if message.contains("❌") {
            return "xmark.circle.fill"
        } else if message.contains("⏳") {
            return "clock.fill"
        } else {
            return "info.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}
