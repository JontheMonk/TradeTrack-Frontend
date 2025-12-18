import SwiftUI
import UIKit

extension View {
    /// Programmatically dismisses the keyboard from any SwiftUI view.
    ///
    /// This works by sending the `resignFirstResponder` action through
    /// the responder chain using UIKit. The action is broadcast to all
    /// potential responders, and whichever view currently owns first responder
    /// status (typically a `UITextField` or `UITextView`) will dismiss the
    /// keyboard.
    ///
    /// ### When to use
    /// - In forms where tapping outside a text field should dismiss the keyboard
    /// - Buttons like “Done”, “Submit”, etc.
    /// - When transitioning to new views and you want to ensure the keyboard
    ///   doesn't linger on-screen
    ///
    /// ### Example
    /// ```swift
    /// VStack {
    ///     TextField("Search", text: $query)
    ///     Button("Dismiss Keyboard") {
    ///         hideKeyboard()
    ///     }
    /// }
    /// ```
    ///
    /// **Note:** This uses UIKit under the hood because SwiftUI still lacks a
    /// built-in public API for dismissing the keyboard globally.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
