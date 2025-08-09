import SwiftUI
// 1) Add this small view somewhere in your file
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
                        Text(opt.label)
                            .font(.callout.weight(.semibold))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .background(isSelected(opt.value) ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(isSelected(opt.value) ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected(opt.value) ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(radius: isSelected(opt.value) ? 4 : 0)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func isSelected(_ v: String) -> Bool { role == v }
}
