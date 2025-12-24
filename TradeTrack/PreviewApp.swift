import SwiftUI
import TradeTrackCore

struct PreviewApp: App {
    var body: some Scene {
        WindowGroup {
            VerificationView(
                viewModel: VerificationViewModel(
                    camera: MockCameraManager(),
                    analyzer: MockFaceAnalyzer(),
                    collector: MockFaceCollector(),
                    processor: MockFaceProcessor(),
                    verifier: MockFaceVerificationService(),
                    errorManager: MockErrorManager(),
                    employeeId: "Preview_User"
                )
            )
        }
    }
}
