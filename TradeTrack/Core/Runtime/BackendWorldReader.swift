import Foundation

/// Reads the active `BackendWorld` from the app’s launch arguments.
///
/// `BackendWorldReader` is responsible for determining **which simulated
/// backend universe** the app should run against during a UI test session.
///
/// How it works:
/// - UI tests launch the app with a `-BackendWorld <value>` argument
/// - This reader extracts and validates that value at runtime
/// - The selected world remains fixed for the entire app lifecycle
///
/// Design notes:
/// - The backend world is chosen **once**, at app launch
/// - The value is immutable for the duration of the run
/// - Missing or invalid configuration is treated as a test failure
///
/// This type intentionally crashes if the backend world is not specified.
/// Silent fallbacks would make UI tests non-deterministic and mask
/// configuration errors.
enum BackendWorldReader {

    /// Returns the backend world specified in the launch arguments.
    ///
    /// - Returns: The `BackendWorld` selected by the UI test harness.
    ///
    /// - Important:
    ///   UI tests **must** launch the app with:
    ///
    ///   `-BackendWorld <BackendWorld>`
    ///
    ///   where `<BackendWorld>` matches one of the enum’s raw values.
    ///
    /// - Fatal error:
    ///   If the argument is missing, malformed, or does not correspond
    ///   to a valid `BackendWorld`, the app will intentionally crash.
    ///
    /// This behavior enforces explicit test configuration and prevents
    /// tests from accidentally running against an unintended backend state.
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
