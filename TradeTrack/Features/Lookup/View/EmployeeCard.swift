/// A lightweight, reusable list row used in employee-search results.
///
/// `EmployeeCard` displays:
///  • the employee’s name
///  • role (as a colored chip)
///  • employee ID (also as a chip)
///  • a leading avatar icon
///  • a trailing chevron indicating navigability
///
/// This view is intentionally presentation-only:
/// it contains **no navigation logic** and delegates taps to the parent
/// (e.g., a `NavigationLink` or `.onTapGesture` in the list).
///
/// Designed for:
///   – LookupView search results
///   – Any compact employee summary UI
///
/// Visual notes:
///   – `.ultraThinMaterial` background provides iOS-style blur
///   – subtle shadow + stroke for card separation
///   – chips use continuous corners to fit the modern UI style

import SwiftUI
import TradeTrackCore

struct EmployeeCard: View {
    let employee: EmployeeResult

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().fill(.ultraThinMaterial)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 28))
                    .opacity(0.9)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.system(size: 18, weight: .semibold))
                HStack(spacing: 8) {
                    roleChip(employee.role)
                    idChip(employee.employeeId)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.headline)
                .opacity(0.25)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 8)
    }

    private func roleChip(_ role: String) -> some View {
        Text(role)
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.blue.opacity(0.15))
            )
    }

    private func idChip(_ id: String) -> some View {
        Text("#\(id)")
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
            )
    }
}
