import Foundation
import SwiftUI
import os.log

@MainActor
final class ErrorManager: ObservableObject {
    @Published var currentError: AppError?

    private let logger = Logger(subsystem: "com.tradetrack", category: "error")

    func show(_ error: AppError) {
        log(error)
        currentError = error
    }

    func clear() {
        currentError = nil
    }

    private func log(_ error: AppError) {
        logger.error("AppError: \(error.code.rawValue, privacy: .public) - \(error.localizedDescription, privacy: .public)")
    }
}
