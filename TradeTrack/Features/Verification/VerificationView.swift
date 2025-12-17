import SwiftUI

/// A live face-verification screen.
///
/// Displays:
///  - A circular camera preview
///  - Dynamic status text ("Looking for a face…", "Verifying…", or success message)
///
/// The view model handles:
///  - Starting/stopping the camera session
///  - Frame analysis
///  - Talking to the backend for recognition
///
/// This view only concerns itself with SwiftUI layout and state display.
struct VerificationView: View {

    /// The view model must live for the lifetime of this view,
    /// so it’s created as a `StateObject`.
    @StateObject private var vm: VerificationViewModel

    /// Designated initializer so callers supply a pre-configured VM.
    init(viewModel: VerificationViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Solid background so the camera isn’t behind anything.
            Color.white.ignoresSafeArea()

            // MARK: - Camera Bubble
            CameraPreview(session: vm.session)
                .clipShape(Circle())
                .frame(width: 250, height: 250)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )

            // MARK: - Overlay Status Text
            VStack {
                switch vm.state {

                case .detecting:
                    statusBubble("Looking for a face…")

                case .processing:
                    statusBubble("Verifying…")

                case .matched(let name):
                    statusBubble("✅ \(name)")
                }

                Spacer()
            }
            .padding(.top, 40)
            .animation(.easeInOut(duration: 0.5), value: vm.state)
        }

        // MARK: - Lifecycle
        .task { await vm.start() }  // Start camera + pipeline on appear
        .onDisappear {
            Task { await vm.stop() } // Stop on exit
        }
    }

    // MARK: - UI Helpers
    private func statusBubble(_ text: String) -> some View {
        Text(text)
            .accessibilityIdentifier("verification.status")
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
