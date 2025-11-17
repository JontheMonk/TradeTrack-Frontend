import Foundation
import AVFoundation

enum AppMode {
    case prod
    case uiTest
}

enum AppRuntime {
    static let mode: AppMode = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-UITest") {
            return .uiTest
        }
        #endif
        return .prod
    }()
}
