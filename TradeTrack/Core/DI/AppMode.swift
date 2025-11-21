//
//  AppRuntime.swift
//
//  Determines how the app should behave at runtime (production vs UI tests).
//  This file centralizes environment detection so the rest of the app can
//  simply switch on `AppRuntime.mode`.
//
//  Useful for:
//  - substituting mocks during UI tests
//  - disabling animations or delays in testing
//  - injecting test data
//  - altering camera or network behavior under automation
//

import Foundation
import AVFoundation

/// Represents the high-level runtime mode the app should operate in.
///
/// - `.prod`: Normal production behavior.
/// - `.uiTest`: Special mode used when the app is launched by XCUITest,
///   typically with mocks, disabled animations, and deterministic behavior.
enum AppMode {
    case prod
    case uiTest
}

/// Determines the current runtime mode based on launch arguments.
///
/// This is evaluated once at app startup. If the app is launched with the
/// argument `-UITest` (typically configured in the Xcode test scheme), the
/// mode switches to `.uiTest`. Otherwise it defaults to `.prod`.
///
/// Example usage inside tests:
/// ```
/// app.launchArguments.append("-UITest")
/// app.launch()
/// ```
///
/// The rest of the app can then do:
/// ```
/// if AppRuntime.mode == .uiTest {
///     useMockServices()
/// }
/// ```
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
