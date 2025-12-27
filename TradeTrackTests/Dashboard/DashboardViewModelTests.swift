import XCTest
@testable import TradeTrack
@testable import TradeTrackMocks
@testable import TradeTrackCore

@MainActor
final class DashboardViewModelTests: XCTestCase {
    
    private var mockTimeService: MockTimeTrackingService!
    private var mockError: MockErrorManager!
    private var vm: DashboardViewModel!
    
    override func setUp() {
        super.setUp()
        mockTimeService = MockTimeTrackingService()
        mockError = MockErrorManager()
        
        vm = DashboardViewModel(
            employeeId: "EMP001",
            timeService: mockTimeService,
            errorManager: mockError
        )
    }
    
    override func tearDown() {
        vm = nil
        mockTimeService = nil
        mockError = nil
        super.tearDown()
    }
    
    // MARK: - onAppear Tests
    
    func test_onAppear_fetchesStatus() async {
        mockTimeService.stubbedStatus = ClockStatus(isClockedIn: true, clockInTime: Date())
        
        await vm.onAppear()
        
        XCTAssertEqual(mockTimeService.getStatusCallCount, 1)
        XCTAssertEqual(mockTimeService.lastGetStatusEmployeeId, "EMP001")
        XCTAssertTrue(vm.isClockedIn)
        XCTAssertNotNil(vm.clockInTime)
    }
    
    func test_onAppear_notClockedIn_setsStateCorrectly() async {
        mockTimeService.stubbedStatus = ClockStatus(isClockedIn: false, clockInTime: nil)
        
        await vm.onAppear()
        
        XCTAssertFalse(vm.isClockedIn)
        XCTAssertNil(vm.clockInTime)
    }
    
    func test_onAppear_failure_showsError() async {
        mockTimeService.stubbedError = AppError(code: .networkUnavailable)
        
        await vm.onAppear()
        
        XCTAssertNotNil(mockError.lastError)
        XCTAssertEqual(mockError.lastError?.code, .networkUnavailable)
    }
    
    // MARK: - Clock In Tests
    
    func test_toggleClock_whenNotClockedIn_callsClockIn() async {
        vm.isClockedIn = false
        let expectedTime = Date()
        mockTimeService.stubbedClockInStatus = ClockStatus(isClockedIn: true, clockInTime: expectedTime)
        
        await vm.toggleClock()
        
        XCTAssertEqual(mockTimeService.clockInCallCount, 1)
        XCTAssertEqual(mockTimeService.clockOutCallCount, 0)
        XCTAssertEqual(mockTimeService.lastClockInEmployeeId, "EMP001")
        XCTAssertTrue(vm.isClockedIn)
        XCTAssertEqual(vm.clockInTime, expectedTime)
    }
    
    func test_toggleClock_clockInFailure_showsError() async {
        vm.isClockedIn = false
        mockTimeService.stubbedError = AppError(code: .alreadyClockedIn)
        
        await vm.toggleClock()
        
        XCTAssertNotNil(mockError.lastError)
        XCTAssertEqual(mockError.lastError?.code, .alreadyClockedIn)
        XCTAssertFalse(vm.isClockedIn)  // State unchanged on error
    }
    
    // MARK: - Clock Out Tests
    
    func test_toggleClock_whenClockedIn_callsClockOut() async {
        vm.isClockedIn = true
        vm.clockInTime = Date()
        mockTimeService.stubbedClockOutStatus = ClockStatus(isClockedIn: false, clockInTime: nil)
        
        await vm.toggleClock()
        
        XCTAssertEqual(mockTimeService.clockOutCallCount, 1)
        XCTAssertEqual(mockTimeService.clockInCallCount, 0)
        XCTAssertEqual(mockTimeService.lastClockOutEmployeeId, "EMP001")
        XCTAssertFalse(vm.isClockedIn)
        XCTAssertNil(vm.clockInTime)
    }
    
    func test_toggleClock_clockOutFailure_showsError() async {
        vm.isClockedIn = true
        mockTimeService.stubbedError = AppError(code: .notClockedIn)
        
        await vm.toggleClock()
        
        XCTAssertNotNil(mockError.lastError)
        XCTAssertEqual(mockError.lastError?.code, .notClockedIn)
        XCTAssertTrue(vm.isClockedIn)  // State unchanged on error
    }
    
    // MARK: - Loading State Tests
    
    func test_isLoading_preventsDuplicateCalls() async {
        mockTimeService.stubbedClockInStatus = ClockStatus(isClockedIn: true, clockInTime: Date())
        
        let t1 = Task { await vm.toggleClock() }
        
        await Task.yield()
        
        XCTAssertTrue(vm.isLoading)
        
        let t2 = Task { await vm.toggleClock() }
        
        await t1.value
        await t2.value
        
        XCTAssertEqual(mockTimeService.clockInCallCount, 1)
    }
    
    func test_isLoading_resetsAfterSuccess() async {
        mockTimeService.stubbedClockInStatus = ClockStatus(isClockedIn: true, clockInTime: Date())
        
        await vm.toggleClock()
        
        XCTAssertFalse(vm.isLoading)
    }
    
    func test_isLoading_resetsAfterFailure() async {
        mockTimeService.stubbedError = AppError(code: .unknown)
        
        await vm.toggleClock()
        
        XCTAssertFalse(vm.isLoading)
    }
}
