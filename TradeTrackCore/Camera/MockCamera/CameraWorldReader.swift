import Foundation

/// Reads the active `CameraWorld` from the app’s launch arguments.
///
/// `CameraWorldReader` determines **which simulated camera behavior**
/// the app should run under during a UI test session.
///
/// How it works:
/// - UI tests launch the app with `-CameraWorld <value>`
/// - This reader extracts and validates that value at runtime
/// - The selected world remains fixed for the entire app lifecycle
///
/// Design notes:
/// - The camera world is chosen **once**, at app launch
/// - The value is immutable for the duration of the run
/// - Missing or invalid configuration is treated as a test failure
///
/// This type intentionally crashes if the camera world is not specified.
/// Silent fallbacks would make UI tests non-deterministic and mask
/// configuration errors.
enum CameraWorldReader {

    /// Returns the camera world specified in the launch arguments.
    ///
    /// - Returns: The `CameraWorld` selected by the UI test harness.
    ///
    /// - Important:
    ///   UI tests **must** launch the app with:
    ///
    ///   `-CameraWorld <CameraWorld>`
    ///
    ///   where `<CameraWorld>` matches one of the enum’s raw values.
    ///
    /// - Fatal error:
    ///   If the argument is missing, malformed, or does not correspond
    ///   to a valid `CameraWorld`, the app will intentionally crash.
    static func current() -> CameraWorld {
        let args = ProcessInfo.processInfo.arguments

        guard
            let index = args.firstIndex(of: "-CameraWorld"),
            index + 1 < args.count,
            let world = CameraWorld(rawValue: args[index + 1])
        else {
            fatalError("UI tests must specify -CameraWorld")
        }

        return world
    }
}
