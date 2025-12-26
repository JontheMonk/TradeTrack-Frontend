import SwiftUI
import TradeTrackCore

struct PreviewApp: App {
    var body: some Scene {
        WindowGroup {
            VerificationView(
                viewModel: VerificationViewModel(
                    camera: CoreFactory.makeCameraManager(for: .normal),
                    analyzer: CoreFactory.makeFaceAnalyzer(),
                    collector: CoreFactory.makeFaceCollector(),
                    processor: try! CoreFactory.makeFaceProcessor(),
                    verifier: MockFaceVerificationService(),
                    errorManager: ErrorManager(),
                    employeeId: "Preview_User"
                )
            )
        }
    }
}
