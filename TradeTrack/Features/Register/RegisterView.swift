import SwiftUI

struct RegisterView: View {
    @StateObject private var vm: RegisterViewModel
    @State private var showPicker = false

    init(viewModel: RegisterViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [Color(hex: "0f0f14"), Color(hex: "1a1a24")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .onTapGesture { hideKeyboard() }

            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Register Employee")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    // MARK: - Form Fields
                    VStack(spacing: 16) {
                        customTextField("Employee ID", text: $vm.employeeID)
                        customTextField("Full Name", text: $vm.name)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Role")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            RolePicker(role: $vm.role)
                        }
                        .padding(.horizontal)
                    }

                    // MARK: - Photo Selector
                    Button {
                        showPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: vm.selectedImage == nil ? "photo.badge.plus" : "photo.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text(vm.selectedImage == nil ? "Select Face Image" : "Change Image")
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
                    .padding(.horizontal)

                    // MARK: - Image Preview
                    if let image = vm.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                            .padding(.horizontal)
                    }

                    // MARK: - Submit Button
                    Button {
                        Task { await vm.registerEmployee() }
                    } label: {
                        Text("Add to Database")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                vm.isFormValid
                                    ? LinearGradient(
                                        colors: [Color.green, Color(hex: "0d8b3d")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color(hex: "2a2a35"), Color(hex: "1a1a24")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        vm.isFormValid ? Color.white.opacity(0.2) : Color.gray.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: vm.isFormValid ? Color.green.opacity(0.4) : Color.clear,
                                radius: vm.isFormValid ? 12 : 0,
                                y: vm.isFormValid ? 6 : 0
                            )
                    }
                    .disabled(!vm.isFormValid)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.isFormValid)
                    .padding(.horizontal)

                    // MARK: - Status Text
                    if !vm.status.isEmpty {
                        Text(vm.status)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(vm.status.contains("✅") ? .green : vm.status.contains("❌") ? .red : .gray)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .sheet(isPresented: $showPicker) {
                ImagePicker(image: $vm.selectedImage)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Custom Text Field Builder

    @ViewBuilder
    private func customTextField(
        _ placeholder: String,
        text: Binding<String>
    ) -> some View {
        TextField(placeholder, text: text)
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
                    .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
            )
            .padding(.horizontal)
            .textInputAutocapitalization(.never)
            .onSubmit { hideKeyboard() }
    }
}
