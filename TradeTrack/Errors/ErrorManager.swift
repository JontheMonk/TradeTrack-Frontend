import Foundation
import SwiftUI
import os.log

/// A centralized controller for presenting errors to the UI and logging them.
///
/// `ErrorManager` serves three roles:
/// 1. **Normalizing errors** — Any thrown `Error` is transformed into an `AppError`,
///    guaranteeing that the UI always receives a consistent, typed payload.
/// 2. **Publishing UI state** — The `@Published currentError` drives error banners
///    and any other global app error UI.
/// 3. **Structured logging** — All errors are logged to the unified system logger
///    with `os.log`, including the underlying `Error` when available.
///
///
/// ### Threading
/// - `showError(_:)` may be called from any thread.
///   It immediately hops to the main actor before mutating UI state.
/// - `show(_:)` is `@MainActor` and safe for direct UI calls.
///
///
/// ### Why a dedicated manager?
/// - Keeps view models simple — they never construct UI messages themselves.
/// - Ensures one place handles logging, normalization, and state publishing.
/// - Makes errors testable and predictable across the entire app.
///
///
/// ### Usage
/// ```swift
/// do {
///     try await cameraManager.start(delegate: self)
/// } catch {
///     errorManager.showError(error)
/// }
/// ```
///
/// The UI observes `currentError` and animates in a banner when set.
final class ErrorManager: ObservableObject, ErrorHandling {

    /// The currently displayed error for the UI.
    /// When non-nil, `ErrorBannerView` animates into view.
    @Published private(set) var currentError: AppError?

    /// Structured system logger for error events.
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "error")

    /// Public entry point for showing errors from any thread.
    /// Converts a raw `Error` into a normalized `AppError`.
    func showError(_ error: Error) {
        Task { @MainActor in self.show(error) }
    }

    /// MainActor version of error presentation.
    /// Immediately logs the error and publishes it to the UI.
    @MainActor
    func show(_ error: Error) {
        let appError: AppError

        // Normalize generic Errors into structured AppErrors.
        if let e = error as? AppError {
            appError = e
        } else {
            appError = AppError(code: .unknown, underlyingError: error)
        }

        log(appError)
        currentError = appError
    }

    /// Clears the currently displayed error.
    @MainActor
    func clear() { currentError = nil }

    /// Logs the error code + optional debug message + underlying error.
    private func log(_ error: AppError) {
        logger.error("AppError: \(error.code.rawValue, privacy: .public) - \(error.debugMessage ?? "No debug message", privacy: .public)")

        if let underlying = error.underlyingError {
            let msg = (underlying as? LocalizedError)?.errorDescription
                ?? String(describing: underlying)
            logger.error("Underlying error: \(msg, privacy: .public)")
        }
    }
}
