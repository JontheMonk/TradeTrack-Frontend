import XCTest
import UIKit
@testable import TradeTrack
@testable import TradeTrackMocks

@MainActor
final class RegisterViewModelTests: XCTestCase {

    private var mockError: MockErrorManager!
    private var mockEmbed: MockEmbeddingService!
    private var mockAPI: MockRegistrationAPI!
    private var vm: RegisterViewModel!

    override func setUp() {
        super.setUp()
        mockError = MockErrorManager()
        mockEmbed = MockEmbeddingService()
        mockAPI = MockRegistrationAPI()

        vm = RegisterViewModel(
            errorManager: mockError,
            face: mockEmbed,
            api: mockAPI
        )
    }

    override func tearDown() {
        vm = nil
        mockError = nil
        mockEmbed = nil
        mockAPI = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertEqual(vm.employeeID, "")
        XCTAssertEqual(vm.name, "")
        XCTAssertEqual(vm.role, .employee)
        XCTAssertNil(vm.selectedImage)
        XCTAssertEqual(vm.status, "Ready")
        XCTAssertFalse(vm.isSubmitting)
    }

    // MARK: - Form Validation Tests

    func test_formInvalid_preventsRegistration() async {
        vm.employeeID = ""
        vm.name = ""
        vm.selectedImage = nil

        await vm.registerEmployee()

        XCTAssertEqual(mockAPI.callCount, 0)
        XCTAssertEqual(vm.status, "Fill all fields and select a valid image")
        XCTAssertFalse(vm.isSubmitting)
    }

    func test_isFormValid_returnsFalse_whenFieldsEmpty() {
        vm.employeeID = ""
        vm.name = ""
        vm.selectedImage = nil

        XCTAssertFalse(vm.isFormValid)
    }

    func test_isFormValid_returnsTrue_whenAllFieldsFilled() {
        vm.employeeID = "101"
        vm.name = "Alice"
        vm.role = .employee
        vm.selectedImage = UIImage(systemName: "person")!

        XCTAssertTrue(vm.isFormValid)
    }

    // MARK: - Role Tests

    func test_role_defaultsToEmployee() {
        XCTAssertEqual(vm.role, .employee)
    }

    func test_role_canBeSetToAdmin() {
        vm.role = .admin
        XCTAssertEqual(vm.role, .admin)
    }

    func test_role_canBeSetToEmployee() {
        vm.role = .admin
        vm.role = .employee
        XCTAssertEqual(vm.role, .employee)
    }

    // MARK: - Registration Tests

    func test_successfulRegistration_resetsForm() async {
        vm.employeeID = "101"
        vm.name = "Alice"
        vm.role = .employee
        vm.selectedImage = UIImage(systemName: "person")!

        await vm.registerEmployee()

        // Embedding was generated
        XCTAssertEqual(mockEmbed.callCount, 1)

        // API was called
        XCTAssertEqual(mockAPI.callCount, 1)
        XCTAssertEqual(mockAPI.lastInput?.employeeId, "101")
        XCTAssertEqual(mockAPI.lastInput?.name, "Alice")
        XCTAssertEqual(mockAPI.lastInput?.role, "Employee") // Converted to string

        // UI State
        XCTAssertEqual(vm.status, "Registered Alice")
        XCTAssertEqual(vm.employeeID, "")
        XCTAssertEqual(vm.name, "")
        XCTAssertEqual(vm.role, .employee) // Reset to default enum value
        XCTAssertNil(vm.selectedImage)
    }

    func test_successfulRegistration_withAdminRole_convertsToString() async {
        vm.employeeID = "101"
        vm.name = "Admin User"
        vm.role = .admin
        vm.selectedImage = UIImage(systemName: "person")!

        await vm.registerEmployee()

        XCTAssertEqual(mockAPI.callCount, 1)
        XCTAssertEqual(mockAPI.lastInput?.role, "Admin") // Enum converted to string
    }

    func test_embeddingFailure_showsError() async {
        struct EmbedError: Error {}
        mockEmbed.stubbedError = EmbedError()

        vm.employeeID = "101"
        vm.name = "Alice"
        vm.role = .employee
        vm.selectedImage = UIImage(systemName: "person")!

        await vm.registerEmployee()

        XCTAssertNotNil(mockError.lastError)
        XCTAssertEqual(vm.status, "Failed to register face")
        XCTAssertEqual(mockAPI.callCount, 0)
    }

    func test_apiFailure_showsError() async {
        struct APIError: Error {}
        mockAPI.stubbedError = APIError()

        vm.employeeID = "101"
        vm.name = "Alice"
        vm.role = .employee
        vm.selectedImage = UIImage(systemName: "person")!

        await vm.registerEmployee()

        XCTAssertNotNil(mockError.lastError)
        XCTAssertEqual(mockAPI.callCount, 1)
        XCTAssertEqual(vm.status, "Failed to register face")
    }

    func test_isSubmitting_preventsDuplicateSubmissions() async {
        vm.employeeID = "101"
        vm.name = "Alice"
        vm.role = .employee
        vm.selectedImage = UIImage(systemName: "person")!

        let t1 = Task { await vm.registerEmployee() }

        await Task.yield()

        XCTAssertTrue(vm.isSubmitting)

        let t2 = Task { await vm.registerEmployee() }

        await t1.value
        await t2.value

        XCTAssertEqual(mockAPI.callCount, 1)
    }

    // MARK: - Image Handling Tests

    func test_setSelectedImage_updatesStatus() {
        XCTAssertEqual(vm.status, "Ready")
        vm.setSelectedImage(UIImage())
        XCTAssertEqual(vm.status, "Image selected")
    }

    func test_setSelectedImage_nil_doesNotUpdateStatus() {
        vm.status = "Custom status"
        vm.setSelectedImage(nil)
        XCTAssertEqual(vm.status, "Custom status")
    }
}
