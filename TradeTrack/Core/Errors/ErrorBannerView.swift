import SwiftUI

struct ErrorBannerView: View {
    @EnvironmentObject var errorManager: ErrorManager

    var body: some View {
        VStack(spacing: 0) {
            if let error = errorManager.currentError {
                HStack(spacing: 8) {
                    Text(userMessage(for: error.code))
                        .font(.callout)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Dismiss") { dismiss() }
                        .foregroundColor(.white)
                        .font(.callout.bold())
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .onTapGesture { dismiss() }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .animation(.easeInOut, value: errorManager.currentError != nil)
        .onChange(of: errorManager.currentError != nil) { show in
            if show { autoDismiss(after: 4) }
        }
    }

    private func dismiss() {
        errorManager.currentError = nil
    }

    private func autoDismiss(after seconds: Double) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            // Only clear if still showing
            if errorManager.currentError != nil { dismiss() }
        }
    }
}
