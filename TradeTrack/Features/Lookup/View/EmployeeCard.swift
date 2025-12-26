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
                Circle().fill(Color.white.opacity(0.08))
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    roleChip(employee.role)
                    idChip(employee.employeeId)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(14)
        // Solid dark background or very dark glass
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func roleChip(_ role: String) -> some View {
        Text(role)
            .font(.caption).bold()
            .foregroundStyle(.cyan)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.cyan.opacity(0.15))
            )
    }

    private func idChip(_ id: String) -> some View {
        Text("#\(id)")
            .font(.caption).bold()
            .foregroundStyle(.gray)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.1))
            )
    }
}
