import Foundation

private class CoreTestsBundleFinder {}

extension Bundle {
    static var tradeTrackCoreTests: Bundle {
        return Bundle(for: CoreTestsBundleFinder.self)
    }
}
