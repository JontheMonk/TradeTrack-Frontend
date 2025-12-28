import SwiftUI

/// Screen for registering a new employee.
///
/// Responsibilities:
/// ---------------------------
/// • Renders the registration form (ID, name, role)
/// • Lets the user pick a face image
/// • Previews the selected image
/// • Binds directly to `RegisterViewModel` for validation and submission
/// • Runs `vm.registerEmployee()` inside a Task
///
/// Notes:
/// • The view owns its ViewModel via `@StateObject`, keeping its lifetime stable.
/// • Navigation & business logic are entirely inside the ViewModel.
/// • The keyboard is dismissed when tapping the background.
struct RegisterView: View {
    @StateObject private var vm: RegisterViewModel
    @State private var showPicker = false

    /// Injects the ViewModel from outside, allowing previews/tests to pass mocks.
    init(viewModel: RegisterViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Background tap → hide keyboard
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { hideKeyboard() }

            VStack(spacing: 20) {
                Text("Register Employee")
                    .font(.largeTitle.bold())
                    .padding(.top)

                // MARK: - Form Fields
                Group {
                    customTextField("Employee ID", text: $vm.employeeID)
                    customTextField("Full Name", text: $vm.name)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Role")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        RolePicker(role: $vm.role)
                    }
                    .padding(.horizontal)
                }

                // MARK: - Photo Selector
                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Image(systemName: "photo")
                        Text(vm.selectedImage == nil ? "Select Face Image" : "Change Image")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }

                // MARK: - Image Preview
                if let image = vm.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5)
                        .padding(.top, 10)
                }

                // MARK: - Submit Button
                Button {
                    Task { await vm.registerEmployee() }
                } label: {
                    Text("Add to Database")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.isFormValid ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: vm.isFormValid ? 6 : 0)
                        .animation(.easeInOut, value: vm.isFormValid)
                }
                .disabled(!vm.isFormValid)

                // MARK: - Status Text
                if !vm.status.isEmpty {
                    Text(vm.status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
            .sheet(isPresented: $showPicker) {
                ImagePicker(image: $vm.selectedImage)
            }
        }
    }

    // MARK: - Custom Text Field Builder

    /// Shared styling for the ID + Name fields.
    @ViewBuilder
    private func customTextField(
        _ placeholder: String,
        text: Binding<String>
    ) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            .textInputAutocapitalization(.never)
            .onSubmit { hideKeyboard() }
    }
}
