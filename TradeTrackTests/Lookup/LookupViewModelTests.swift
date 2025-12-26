import XCTest
@testable import TradeTrack
@testable import TradeTrackCore
@testable import TradeTrackMocks

@MainActor
final class LookupViewModelTests: XCTestCase {

    // MARK: - Mocks

    private var mockService: MockEmployeeLookupService!
    private var mockNavigator: MockNavigator!
    private var mockError: MockErrorManager!
    private var vm: LookupViewModel!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockService = MockEmployeeLookupService()
        mockNavigator = MockNavigator()
        mockError = MockErrorManager()

        vm = LookupViewModel(
            service: mockService,
            errorManager: mockError,
            navigator: LookupNavigator(nav: mockNavigator)
        )
    }

    override func tearDown() {
        vm = nil
        mockService = nil
        mockNavigator = nil
        mockError = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_selectEmployee_pushesVerificationRoute() {
        // When
        vm.selectEmployee("123")

        // Then
        XCTAssertEqual(mockNavigator.pushed.count, 1)
        XCTAssertEqual(
            mockNavigator.pushed.first,
            .verification(employeeId: "123")
        )
    }

    func test_shortQuery_clearsResultsImmediately() {
        // When
        vm.setQuery("ab")   // < 3 chars

        // Then
        XCTAssertEqual(vm.results.count, 0)
        XCTAssertEqual(vm.isLoading, false)
        XCTAssertEqual(mockService.callCount, 0)
    }

    func test_performsSearch_afterDebounce() async {
        // Given
        mockService.stubbedResults = [
            EmployeeResult(employeeId: "1", name: "Alice", role: "employee")
        ]

        // When
        vm.setQuery("ali")

        // Wait longer than the debounce (350ms)
        try? await Task.sleep(for: .milliseconds(450))

        // Then
        XCTAssertEqual(mockService.callCount, 1)
        XCTAssertEqual(vm.results.count, 1)
        XCTAssertEqual(vm.results.first?.name, "Alice")
        XCTAssertEqual(vm.isLoading, false)
    }

    func test_cancelsOldSearch_whenQueryChanges() async {
        // Given
        mockService.stubbedResults = [
            EmployeeResult(employeeId: "1", name: "Alice", role: "employee")
        ]

        // Start a first query
        vm.setQuery("ali")

        // Immediately change query before debounce fires
        vm.setQuery("alex")

        // Wait long enough for second debounce to fire
        try? await Task.sleep(for: .milliseconds(450))

        // Then: only the final query should run
        XCTAssertEqual(mockService.callCount, 1)
        XCTAssertEqual(vm.results.first?.name, "Alice")
    }

    func test_serviceError_showsErrorBanner() async {
        // Given
        struct TestError: Error {}
        mockService.stubbedError = TestError()

        // When
        vm.setQuery("abc")
        try? await Task.sleep(for: .milliseconds(450))

        // Then
        XCTAssertNotNil(mockError.lastError)
    }

    func test_emptyResults_showsNoError() async {
        // Given
        mockService.stubbedResults = []

        // When
        vm.setQuery("xyz")
        try? await Task.sleep(for: .milliseconds(450))

        // Then
        XCTAssertEqual(vm.results.count, 0)
        XCTAssertNil(mockError.lastError)
    }
}
