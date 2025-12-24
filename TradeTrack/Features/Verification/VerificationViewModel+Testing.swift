//
//  VerificationViewModel+Testing.swift
//

import Vision
import CoreImage
import TradeTrackCore
import Synchronization

#if DEBUG
extension VerificationViewModel {

    // MARK: - UI Test Bridge
    
    func installUITestSignalBridge() {
        guard AppRuntime.mode == .uiTest else { return }
        
        let center = NotificationCenter.default
        
        let observer1 = center.addObserver(
            forName: .uiTestCameraNoFace,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.state = .detecting
            }
        }
        
        let observer2 = center.addObserver(
            forName: .uiTestCameraInvalidFace,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.state = .detecting
                self?.errorManager.showError(AppError(code: .faceConfidenceTooLow))
            }
        }

        let observer3 = center.addObserver(
            forName: .uiTestCameraValidFace,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.state = .matched(name: "Test User")
            }
        }
        
        self.uiTestObservers.append(contentsOf: [observer1, observer2, observer3])
    }
}
#endif
