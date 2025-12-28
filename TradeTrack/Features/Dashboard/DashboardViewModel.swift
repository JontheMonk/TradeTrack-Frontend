import Foundation
import TradeTrackCore

/// ViewModel for the main dashboard after successful verification.
///
/// Responsibilities:
/// ------------------------------------------------
/// • Fetches current clock status on appear
/// • Handles clock in/out toggle
/// • Exposes UI state for the clock button and status display
/// • Reports errors through ErrorManager
@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - UI State
    
    /// Whether the employee is currently clocked in.
    @Published var isClockedIn = false
    
    /// The timestamp when the current shift started (nil if not clocked in).
    @Published var clockInTime: Date?
    
    /// Whether a clock operation is in progress.
    @Published var isLoading = false
    
    // MARK: - Employee Info
    
    /// The verified employee's ID (passed from verification).
    let employeeId: String
    
    // MARK: - Dependencies
    
    private let timeService: TimeTrackingServing
    private let errorManager: ErrorHandling
    private let navigator: DashboardNavigator
    
    // MARK: - Init
    
    init(
        employeeId: String,
        timeService: TimeTrackingServing,
        errorManager: ErrorHandling,
        navigator: DashboardNavigator
    ) {
        self.employeeId = employeeId
        self.timeService = timeService
        self.errorManager = errorManager
        self.navigator = navigator
    }
    
    // MARK: - Lifecycle
    
    /// Fetches the current clock status when the view appears.
    func onAppear() async {
        await fetchStatus()
    }
    
    // MARK: - Actions
    
    /// Toggles clock state: clocks in if out, clocks out if in.
    func toggleClock() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let status: ClockStatus
            if isClockedIn {
                status = try await timeService.clockOut(employeeId: employeeId)
            } else {
                status = try await timeService.clockIn(employeeId: employeeId)
            }
            applyStatus(status)
        } catch {
            errorManager.showError(error)
        }
    }
    
    func signOut() {
        navigator.signOut()
    }
    
    // MARK: - Helpers
    
    private func fetchStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let status = try await timeService.getStatus(employeeId: employeeId)
            applyStatus(status)
        } catch {
            errorManager.showError(error)
        }
    }
    
    private func applyStatus(_ status: ClockStatus) {
        isClockedIn = status.isClockedIn
        clockInTime = status.clockInTime
    }
}
