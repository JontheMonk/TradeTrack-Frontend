//
//  AppError.swift
//
//  Unified error type used across the entire app.
//
//  `AppError` wraps all domain, network, and camera errors into a single,
//  consistent structure. It carries both user-facing messages (based on
//  `AppErrorCode`) and developer/debug information (debugMessage,
//  underlyingError). This ensures:
//
//  - predictable error handling throughout the app
//  - clean UI presentation via `LocalizedError`
//  - full debuggability without exposing technical messages to the user
//  - safe comparison in SwiftUI alerts using stable identity
//

import Foundation

/// A strongly-typed error used throughout the app.
///
/// `AppError` separates three layers of information:
///
/// 1. **User-facing message**
///    - Derived from `AppErrorCode`
///    - Safe to show in UI (via `LocalizedError`)
///
/// 2. **Debug message**
///    - Optional developer-oriented context
///    - Not shown to users, but logged internally
///
/// 3. **Underlying error**
///    - Raw technical error (e.g. network error, AVFoundation error)
///    - Helps during debugging/testing without leaking details to UI
///
/// `AppError` is identifiable so SwiftUI alerts can bind to it directly.
/// Equality uses the UUID so each instance is unique, even if the code
/// and debug info match.
struct AppError: Error, LocalizedError, Equatable, Identifiable {

    /// Unique identity for this particular error instance.
    /// Allows SwiftUI views to present alerts bound to `AppError?`.
    let id = UUID()

    /// High-level category of error for user-facing descriptions.
    let code: AppErrorCode

    /// Additional internal context for logs or debugging.
    let debugMessage: String?

    /// The underlying system or domain error that triggered this one.
    let underlyingError: Error?

    /// Creates a new application error with optional debugging details.
    init(
        code: AppErrorCode,
        debugMessage: String? = nil,
        underlyingError: Error? = nil
    ) {
        self.code = code
        self.debugMessage = debugMessage
        self.underlyingError = underlyingError
    }

    /// Human-readable description shown to the user.
    /// Resolved through your `userMessage(for:)` helper.
    var errorDescription: String? {
        userMessage(for: code)
    }

    /// Error equality is defined by identity, not contents.
    /// This ensures that two separate errors with the same code do **not**
    /// collapse into the same SwiftUI alert.
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }
}
