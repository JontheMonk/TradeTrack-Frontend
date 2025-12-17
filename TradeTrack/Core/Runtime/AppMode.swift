//
//  AppRuntime.swift
//
//  Determines how the app should behave at runtime (normal vs UI tests).
//  This allows us to inject mocks, disable animations, and avoid real network
//  or camera usage when the app runs under XCUITest.
//

import Foundation

/// The high-level runtime behavior mode of the app.
///
/// - normal: Standard runtime (manual dev testing or production)
/// - uiTest: App launched via XCUITest; use mocks and deterministic behavior.
enum AppMode {
    case normal
    case uiTest
}

/// Reads launch arguments once at startup to determine test mode.
///
/// UITests pass "-UITest" in launchArguments, so we detect that and switch
/// the entire app into a deterministic test environment.
///
/// Example:
/// ```swift
/// app.launchArguments.append("-UITest")
/// app.launch()
/// ```
///
enum AppRuntime {
    static let mode: AppMode = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-UITest") {
            return .uiTest
        }
        #endif

        return .normal
    }()
}
