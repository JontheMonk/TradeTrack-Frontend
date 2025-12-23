import SwiftUI
import TradeTrackCore

struct PreviewApp: App {
    var body: some Scene {
        WindowGroup {
            VerificationView(
                viewModel: VerificationViewModel(
                    camera: CoreFactory.makeCameraManager(for: .normal),
                    analyzer: CoreFactory.makeFaceAnalyzer(),
                    processor: MockFaceProcessor(),
                    verifier: MockFaceVerificationService(),
                    errorManager: MockErrorManager(),
                    employeeId: "Preview_User"
                )
            )
        }
    }
}
