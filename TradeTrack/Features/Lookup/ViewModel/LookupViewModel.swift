import Foundation

@MainActor
final class LookupViewModel: ObservableObject {
    @Published private(set) var query = ""
    @Published private(set) var results: [EmployeeResult] = []
    @Published private(set) var isLoading = false

    private let service: EmployeeLookupServing
    private let errorManager: ErrorManager
    private var searchTask: Task<Void, Never>?
    private var generation = 0
    private let debounceNs: UInt64 = 350_000_000

    init(service: EmployeeLookupServing, errorManager: ErrorManager) {
        self.service = service
        self.errorManager = errorManager
    }

    func setQuery(_ newValue: String) {
        query = newValue
        onQueryChanged()
    }

    private func onQueryChanged() {
        searchTask?.cancel()
        generation &+= 1
        let gen = generation

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            Task { @MainActor in
                if self.generation == gen { self.results = []; self.isLoading = false }
            }
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: debounceNs)
                await MainActor.run {
                    if self.generation == gen { self.isLoading = true }
                }

                let found = try await self.service.search(prefix: trimmed)
                try Task.checkCancellation()

                await MainActor.run {
                    guard self.generation == gen else { return }
                    self.results = found
                    self.isLoading = false
                }
            } catch is CancellationError {
                await MainActor.run {
                    if self.generation == gen { self.isLoading = false }
                }
            } catch {
                await MainActor.run {
                    if self.generation == gen {
                        self.errorManager.show(error)
                        self.results = []
                        self.isLoading = false
                    }
                }
            }
        }
    }

    deinit { searchTask?.cancel() }
}
