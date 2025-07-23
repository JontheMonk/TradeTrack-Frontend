import SwiftUI

struct RegisterView: View {
    @StateObject private var vm = RegisterViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Register Employee")
                .font(.largeTitle.bold())
                .padding(.top)
                .foregroundColor(.primary)

            Group {
                customTextField("Employee ID", text: $vm.employeeID)
                customTextField("Full Name", text: $vm.name)
            }

            Button(action: {
                vm.showingImagePicker = true
            }) {
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

            Button(action: {
                Task { await vm.registerFace() }
            }) {
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
        .sheet(isPresented: $vm.showingImagePicker) {
            ImagePicker(image: $vm.selectedImage)
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
            .autocapitalization(.none)
    }
}
