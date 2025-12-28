import Foundation
import TradeTrackCore

/// ViewModel for the employee lookup screen.
///
/// This class owns the state and logic for the employee search flow,
/// including:
///  • debounced search requests
///  • cancellation of outdated queries
///  • “generation” tracking so only the latest query updates the UI
///  • error reporting
///  • navigation to the verification screen
///
/// The view does **not** talk directly to the network or navigation layer.
/// It only reads published state (`query`, `results`, `isLoading`) and calls:
///  • `setQuery(_:)`
///  • `selectEmployee(_:)`
///
/// This separation keeps the UI simple and the business logic testable.
@MainActor
final class LookupViewModel: ObservableObject {

    // MARK: - Published State

    /// Current text entered by the user in the search field.
    /// Setting this triggers debounced search logic.
    @Published private(set) var query = ""

    /// Search results returned from the backend.
    @Published private(set) var results: [EmployeeResult] = []

    /// Whether a search request is currently in progress.
    @Published private(set) var isLoading = false


    // MARK: - Dependencies

    /// Navigator responsible for pushing new screens.
    private let navigator: LookupNavigator

    /// Backend service that performs the actual lookup.
    private let service: EmployeeLookupServing

    /// Centralized error reporter shown via the `ErrorBannerView`.
    private let errorManager: ErrorHandling


    // MARK: - Internal Search State

    /// Current in-flight search task (if any), so we can cancel prior searches.
    private var searchTask: Task<Void, Never>?

    /// Monotonically increasing counter tracking the “version” of the query.
    ///
    /// Ensures that when old searches complete, they do not override results
    /// for a more recent query.
    private var generation = 0

    /// Debounce delay before performing a search.
    private let debounce: Duration = .milliseconds(350)


    // MARK: - Init

    init(
        service: EmployeeLookupServing,
        errorManager: ErrorHandling,
        navigator: LookupNavigator
    ) {
        self.service = service
        self.errorManager = errorManager
        self.navigator = navigator
    }


    // MARK: - Public API (called by the View)

    /// Updates the query text and triggers the debounced search workflow.
    func setQuery(_ newValue: String) {
        query = newValue
        onQueryChanged()
    }

    /// Called when the user taps an employee row.
    /// The view never pushes routes directly — it delegates to the VM.
    func selectEmployee(_ employee: EmployeeResult) {
        navigator.goToVerification(employee: employee)
    }


    // MARK: - Core Search Logic

    /// Handles debouncing, cancellation, and generation tracking whenever
    /// the query changes.
    private func onQueryChanged() {
        // Cancel any previously running search task.
        searchTask?.cancel()

        // Increment generation so stale tasks know they're obsolete.
        generation &+= 1
        let gen = generation

        // Trim whitespace to enforce real query input.
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // If query is too short, immediately clear results + stop loading.
        guard trimmed.count >= 3 else {
            results = []
            isLoading = false
            return
        }

        // Start a new debounced search.
        searchTask = performSearch(for: trimmed, generation: gen)
    }

    /// Performs the actual asynchronous search with debounce, cancellation,
    /// and generation-validation.
    ///
    /// Only the task whose `generation` matches the latest `generation`
    /// may update published state.
    private func performSearch(
        for prefix: String,
        generation gen: Int
    ) -> Task<Void, Never> {

        let svc = service
        let delay = debounce

        return Task(priority: .userInitiated) { [weak self, svc] in
            guard let self else { return }

            do {
                // Debounce wait.
                try await Task.sleep(for: delay)

                // User typed again — cancel.
                try Task.checkCancellation()

                // Indicate loading (only if still latest generation).
                await MainActor.run {
                    if self.generation == gen {
                        self.isLoading = true
                    }
                }

                // Perform search.
                let found = try await svc.search(prefix: prefix)

                // Query changed? Discard results.
                try Task.checkCancellation()

                // Publish results (if still latest generation).
                await MainActor.run {
                    guard self.generation == gen else { return }
                    self.results = found
                    self.isLoading = false
                }

            } catch is CancellationError {
                // Task was cancelled (typist kept typing).
                await MainActor.run {
                    if self.generation == gen {
                        self.isLoading = false
                    }
                }

            } catch {
                // Real error — show banner.
                await MainActor.run {
                    if self.generation == gen {
                        self.isLoading = false
                    }
                    self.errorManager.showError(error)
                }
            }
        }
    }


    // MARK: - Cleanup

    deinit {
        // Clean up any in-flight task on VM deallocation.
        searchTask?.cancel()
    }
}
