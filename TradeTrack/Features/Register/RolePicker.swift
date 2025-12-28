import SwiftUI

/// A simple segmented button control for choosing an employee role.
///
/// This view presents two selectable options:
///   • **Employee** (value: `"employee"`)
///   • **Admin**    (value: `"admin"`)
///
/// It behaves like a custom “segmented control”:
///   • The selected role visually highlights in blue
///   • Tapping an option updates the bound `role` value
///   • Styling remains consistent with your registration form UI
///
/// Usage:
/// ```swift
/// RolePicker(role: $viewModel.role)
/// ```
struct RolePicker: View {
    @Binding var role: String

    /// Local data model for options. Each entry has:
    ///  – A user-facing label
    ///  – A raw backend role value
    ///  – A system icon name
    private let options: [(label: String, value: String, icon: String)] = [
        ("Employee", "employee", "person"),
        ("Admin",    "admin",    "person.badge.key")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.value) { opt in
                Button {
                    role = opt.value
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: opt.icon)
                        Text(opt.label)
                            .font(.callout.weight(.semibold))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected(opt.value)
                            ? Color.blue
                            : Color(.secondarySystemBackground)
                    )
                    .foregroundColor(
                        isSelected(opt.value) ? .white : .primary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected(opt.value)
                                    ? Color.blue
                                    : Color.gray.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .shadow(radius: isSelected(opt.value) ? 4 : 0)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Returns true if the given role value is the currently selected one.
    private func isSelected(_ v: String) -> Bool { role == v }
}
