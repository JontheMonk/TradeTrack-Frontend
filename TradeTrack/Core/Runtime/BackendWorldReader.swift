import Foundation

enum BackendWorldReader {
    static func current() -> BackendWorld {
        let args = ProcessInfo.processInfo.arguments

        guard
            let index = args.firstIndex(of: "-BackendWorld"),
            index + 1 < args.count,
            let world = BackendWorld(rawValue: args[index + 1])
        else {
            fatalError("UI tests must specify -BackendWorld")
        }

        return world
    }
}
