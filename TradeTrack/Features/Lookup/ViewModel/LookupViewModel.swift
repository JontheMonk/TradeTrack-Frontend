import Foundation

@MainActor
final class LookupViewModel: ObservableObject {
    @Published private(set) var query = ""
    @Published private(set) var results: [EmployeeResult] = []
    @Published private(set) var isLoading = false

    private let navigator: LookupNavigator
    private let service: EmployeeLookupServing
    private let errorManager: ErrorManager

    private var searchTask: Task<Void, Never>?
    private var generation = 0
    private let debounce: Duration = .milliseconds(350)

    init(service: EmployeeLookupServing,
         errorManager: ErrorManager,
         navigator: LookupNavigator) {
        self.service = service
        self.errorManager = errorManager
        self.navigator = navigator
    }

    // Called by the View
    func setQuery(_ newValue: String) {
        query = newValue
        onQueryChanged()
    }

    // Called by the View
    func selectEmployee(_ id: String) {
        navigator.goToVerification(id: id)
    }

    private func onQueryChanged() {
        searchTask?.cancel()
        generation &+= 1
        let gen = generation

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            results = []
            isLoading = false
            return
        }

        searchTask = performSearch(for: trimmed, generation: gen)
    }

    private func performSearch(for prefix: String, generation gen: Int) -> Task<Void, Never> {
        let svc = service
        let debounce = self.debounce

        return Task(priority: .userInitiated) { [weak self, svc] in
            guard let self else { return }
            do {
                try await Task.sleep(for: debounce)
                try Task.checkCancellation()

                await MainActor.run {
                    if self.generation == gen { self.isLoading = true }
                }

                let found = try await svc.search(prefix: prefix)
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
                    if self.generation == gen { self.isLoading = false }
                    self.errorManager.show(error)
                }
            }
        }
    }

    deinit { searchTask?.cancel() }
}
