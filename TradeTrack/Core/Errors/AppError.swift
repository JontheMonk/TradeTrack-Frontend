import Foundation

// MARK: - App-Wide Error Struct

struct AppError: Error, LocalizedError, Equatable, Identifiable {
    let id = UUID()
    let code: AppErrorCode
    let debugMessage: String?
    let underlyingError: Error?

    init(
        code: AppErrorCode,
        debugMessage: String? = nil,
        underlyingError: Error? = nil
    ) {
        self.code = code
        self.debugMessage = debugMessage
        self.underlyingError = underlyingError
    }

    var errorDescription: String? {
        userMessage(for: code)
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }
}
