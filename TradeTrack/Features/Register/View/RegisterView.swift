import SwiftUI

struct RegisterView: View {
    @StateObject private var vm: RegisterViewModel
    @State private var showPicker = false

    init(http: HTTPClient, errorManager: ErrorManager) {
        _vm = StateObject(wrappedValue: RegisterViewModel(http: http, errorManager: errorManager))
    }

    var body: some View {
        ZStack {
            // Invisible tappable background to dismiss keyboard anywhere
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { hideKeyboard() }

            VStack(spacing: 20) {
                Text("Register Employee")
                    .font(.largeTitle.bold())
                    .padding(.top)

                Group {
                    customTextField("Employee ID", text: $vm.employeeID)
                    customTextField("Full Name", text: $vm.name)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Role").font(.subheadline).foregroundColor(.secondary)
                        RolePicker(role: $vm.role)
                    }
                    .padding(.horizontal)
                }

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

                if let image = vm.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5)
                        .padding(.top, 10)
                }

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

    @ViewBuilder
    private func customTextField(_ placeholder: String, text: Binding<String>) -> some View {
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
            .onSubmit { hideKeyboard() } // dismiss when user taps return
    }
}
