import Foundation
import SwiftUI
import os.log

final class ErrorManager: ObservableObject {
    @Published private(set) var currentError: AppError?
    private let logger = Logger(subsystem: "Jon.TradeTrack", category: "error")

    func showError(_ error: Error) {
        Task { @MainActor in self.show(error) }
    }

    @MainActor
    func show(_ error: Error) {
        let appError: AppError
        if let e = error as? AppError { appError = e }
        else { appError = AppError(code: .unknown, underlyingError: error) }

        log(appError)
        currentError = appError
    }

    @MainActor
    func clear() { currentError = nil }

    private func log(_ error: AppError) {
        logger.error("AppError: \(error.code.rawValue, privacy: .public) - \(error.debugMessage ?? "No debug message", privacy: .public)")
        if let underlying = error.underlyingError {
            let msg = (underlying as? LocalizedError)?.errorDescription ?? String(describing: underlying)
            logger.error("Underlying error: \(msg, privacy: .public)")
        }
    }
}
