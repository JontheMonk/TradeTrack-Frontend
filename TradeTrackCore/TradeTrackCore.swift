import Foundation

private class InternalBundleFinder {}

extension Bundle {
    /// A helper to find the TradeTrackCore bundle regardless of the environment.
    static var tradeTrackCore: Bundle {
        return Bundle(for: InternalBundleFinder.self)
    }
}
