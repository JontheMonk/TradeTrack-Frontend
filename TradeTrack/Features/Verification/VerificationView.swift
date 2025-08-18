import SwiftUI

struct VerificationView: View {
    @StateObject private var vm: VerificationViewModel

    init(viewModel: VerificationViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            CameraPreview(session: vm.session)
                .clipShape(Circle())
                .frame(width: 250, height: 250)
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))

            VStack {
                switch vm.state {
                case .detecting:
                    Text("Looking for a face…")
                        .padding().background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .processing:
                    ProgressView("Verifying…")
                        .padding().background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .matched(let name):
                    Text("✅ \(name)")
                        .padding().background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
            }
            .padding(.top, 40)
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}
