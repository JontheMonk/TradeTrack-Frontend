import Foundation
import SwiftUI
import os.log

@MainActor
final class ErrorManager: ObservableObject {
    @Published var currentError: AppError?

    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "error")
    
    func showError(_ error: Error) {
        Task { @MainActor in
            show(error)
        }
    }
    
    func show(_ error: Error) {
        if let appError = error as? AppError {
            log(appError)
            currentError = appError
        } else {
            let fallback = AppError(code: .unknown, underlyingError: error)
            log(fallback)
            currentError = fallback
        }
    }

    func clear() {
        currentError = nil
    }

    private func log(_ error: AppError) {
        logger.error("AppError: \(error.code.rawValue, privacy: .public) - \(error.localizedDescription, privacy: .public)")

        if let underlying = error.underlyingError {
            let message: String

            if let localized = underlying as? LocalizedError, let desc = localized.errorDescription {
                message = desc
            } else {
                message = String(describing: underlying)
            }

            logger.error("Underlying error: \(message, privacy: .public)")
        }
    }
}
