import Foundation
import SwiftUI

@MainActor
final class ErrorManager: ObservableObject {
    @Published var currentError: AppError?
    private var clearTask: Task<Void, Never>?

    func show(_ error: AppError, duration: TimeInterval = 3) {
        currentError = error
        clearTask?.cancel()

        clearTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            withAnimation {
                self.currentError = nil
            }
        }
    }

    func clear() {
        currentError = nil
        clearTask?.cancel()
    }
}
