//
//  ErrorBannerView.swift
//
//  A lightweight, animated banner for displaying user-facing errors at the
//  top of the screen. The banner listens to `ErrorManager` via an observed
//  object and automatically appears/disappears with smooth transitions.
//
//  The banner is intended for brief, dismissible notifications (e.g. network
//  errors, camera failures). It auto-dismisses after a configurable delay,
//  but can also be dismissed manually by tapping or pressing the button.
//
//  This component is intentionally simple and reusable across the app.
//

import SwiftUI

/// A slide-down error banner that appears at the top of the screen whenever
/// `ErrorManager` publishes a new `AppError`.
///
/// The banner:
/// - animates in and out
/// - auto-dismisses after a delay
/// - allows manual dismissal
/// - uses `userMessage(for:)` to show friendly, non-technical messages
///
/// Embed this in your root view (typically above your NavigationStack) so
/// it overlays everything:
///
/// ```swift
/// ZStack {
///     NavigationStack { ... }
///     ErrorBannerView(errorManager: container.errorManager)
/// }
/// ```
struct ErrorBannerView: View {

    /// Observed source of errors. When `currentError` becomes non-nil,
    /// the banner animates into view.
    @ObservedObject var errorManager: ErrorManager

    init(errorManager: ErrorManager) {
        self.errorManager = errorManager
    }

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

    // MARK: - Dismissal Logic

    /// Immediately hides the banner with animation.
    @MainActor
    private func dismiss() {
        withAnimation { errorManager.clear() }
    }

    /// Automatically hides the banner after the given number of seconds.
    ///
    /// This helps keep the UI from feeling cluttered, while still giving
    /// the user enough time to read the message.
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
