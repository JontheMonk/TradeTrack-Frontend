import Foundation
@testable import TradeTrackCore

public extension CoreFactory {
    
    /// Configures the mock networking layer using the world specified in launch arguments.
    /// This implementation lives in the Mocks framework so it can access BackendWorldReader.
    static func setupMockNetworking(for environment: AppMode) {
        guard environment == .uiTest else { return }
        
        let world = BackendWorldReader.current()
        MockURLProtocol.requestHandler = MockBackendRouter.handler(for: world)
    }

    /// Returns the UITestCameraManager, which only exists in the Mocks target.
    static func makeUITestCameraManager() -> CameraManagerProtocol {
        let world = CameraWorldReader.current()
        return UITestCameraManager(world: world)
    }
}
