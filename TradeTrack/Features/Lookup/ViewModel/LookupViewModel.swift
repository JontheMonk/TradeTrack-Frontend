import Foundation

final class LookupViewModel: ObservableObject {
    @Published private(set) var query = ""
    @Published private(set) var results: [EmployeeResult] = []
    @Published private(set) var isLoading = false
    private let service: EmployeeLookupServing
    private let errorManager: ErrorManager
    private var searchTask: Task<Void, Never>?

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
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 3 {
            Task { @MainActor in
                self.results = []; self.isLoading = false
            }
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            await self.setLoading(true)
            do {
                let found = try await self.service.search(prefix: trimmed)
                if Task.isCancelled { return }
                await self.setResults(found)
            } catch {
                if Task.isCancelled { return }
                await self.report(error)
                await self.setResults([])
            }
            await self.setLoading(false)
        }
    }

    deinit { searchTask?.cancel() }

    @MainActor private func setLoading(_ flag: Bool) { isLoading = flag }
    @MainActor private func setResults(_ arr: [EmployeeResult]) { results = arr }
    @MainActor private func report(_ error: Error) { errorManager.show(error) }
}
