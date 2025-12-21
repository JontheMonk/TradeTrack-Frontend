import SwiftUI

struct PreviewApp: App {
    var body: some Scene {
        WindowGroup {
            VerificationView(
                viewModel: VerificationViewModel(
                    camera: MockCameraManager(),
                    analyzer: MockFaceAnalyzer(),
                    processor: MockFaceProcessor(),
                    verifier: MockFaceVerificationService(),
                    errorManager: MockErrorManager(),
                    employeeId: "Preview_User"
                )
            )
        }
    }
}
