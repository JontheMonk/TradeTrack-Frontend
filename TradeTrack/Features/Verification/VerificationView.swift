import SwiftUI

struct VerificationView: View {
    @StateObject var vm: VerificationViewModel

    var body: some View {
        ZStack {
            // White background
            Color.white.ignoresSafeArea()

            // Camera feed masked to a circle
            CameraPreview(session: vm.session)
                .clipShape(Circle())
                .frame(width: 250, height: 250) // size of the circle
                .overlay(
                    Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2) // optional border
                )

            VStack {
                // Status text at the top
                switch vm.state {
                case .detecting:
                    Text("Looking for a face…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .processing:
                    ProgressView("Verifying…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .matched(let name):
                    Text("✅ \(name)")
                        .padding()
                        .background(.ultraThinMaterial)
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
