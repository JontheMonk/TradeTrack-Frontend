//
//  Route.swift
//
//  Enum representing all top-level navigation destinations in the app.
//  Used by `AppCoordinator` and any `Navigating` implementation to move
//  between screens in a type-safe, testable way.
//
//  Each case corresponds to a feature module. Associated values are used
//  when a screen requires domain data (e.g., employee ID for verification).
//

/// Represents a destination in the app's navigation flow.
///
/// `Route` is Hashable so it can be used inside a `NavigationStack`
/// (via `NavigationPath`) and compared in unit tests.
///
/// Examples:
/// ```swift
/// navigator.push(.lookup)
/// navigator.push(.verification(employeeId: "123"))
/// navigator.push(.register)
/// ```
enum Route: Hashable {

    /// Employee lookup screen.
    case lookup

    /// Verification screen for a specific employee.
    case verification(employeeId: String)

    /// New-employee registration screen.
    case register
}
