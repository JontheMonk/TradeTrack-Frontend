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
                            .font(.system(size: 14, weight: .semibold))
                        Text(opt.label)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected(opt.value)
                            ? LinearGradient(
                                colors: [Color(hex: "2a5fff"), Color(hex: "1a3dcc")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : Color.white.opacity(0.08)
                    )
                    .foregroundColor(isSelected(opt.value) ? .white : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected(opt.value)
                                    ? Color.white.opacity(0.3)
                                    : Color.white.opacity(0.15),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: isSelected(opt.value) ? Color(hex: "2a5fff").opacity(0.3) : Color.clear,
                        radius: isSelected(opt.value) ? 8 : 0,
                        y: isSelected(opt.value) ? 4 : 0
                    )
                }
            }
        }
    }

    private func isSelected(_ v: String) -> Bool { role == v }
}
