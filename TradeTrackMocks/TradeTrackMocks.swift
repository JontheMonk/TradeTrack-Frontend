import Foundation

private class InternalBundleFinder {}

extension Bundle {
    static var tradeTrackMocks: Bundle {
        return Bundle(for: InternalBundleFinder.self)
    }
}
