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

    @MainActor
    private func dismiss() {
        withAnimation { errorManager.clear() }
    }

    private func autoDismiss(after seconds: Double) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            await MainActor.run {
                if errorManager.currentError != nil {
                    withAnimation { errorManager.clear() }
                }
            }
        }
    }
}
