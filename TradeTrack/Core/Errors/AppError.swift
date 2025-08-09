import Foundation

// MARK: - App-Wide Error Struct

struct AppError: Error, LocalizedError, Equatable, Identifiable {
    let id = UUID()                      // unique for each error instance
    let code: AppErrorCode
    let underlyingError: Error?

    init(code: AppErrorCode, underlyingError: Error? = nil) {
        self.code = code
        self.underlyingError = underlyingError
    }

    var errorDescription: String? {
        userMessage(for: code)
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }
}
