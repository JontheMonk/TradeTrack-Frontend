//
//  Navigating.swift
//
//  Lightweight abstraction for navigation actions used by view models.
//
//  View models should not know about `NavigationStack`, `NavigationPath`,
//  or any SwiftUI-specific APIs. Instead, they depend on this protocol,
//  which allows pushing and popping high-level `Route` values.
//
//  `AppCoordinator` is the concrete implementation used in production.
//  Tests can provide a mock navigator to assert routing behavior.
//

@MainActor
protocol Navigating: AnyObject {

    /// Pushes a new destination onto the navigation stack.
    ///
    /// View models call this to move to another screen without importing
    /// SwiftUI or referencing concrete coordinator types.
    func push(_ route: Route)

    /// Pops the most recent destination from the navigation stack.
    ///
    /// Equivalent to dismissing the current screen.
    func pop()
}
