import SwiftUI

protocol RoleOption: Hashable, CaseIterable {
    var label: String { get }
    var icon: String { get }
}

struct RolePicker<T: RoleOption>: View {
    @Binding var selection: T
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(T.allCases), id: \.self) { option in
                Button(action: { selection = option }) {
                    HStack(spacing: 6) {
                        Image(systemName: option.icon)
                        Text(option.label)
                    }
                }
                .buttonStyle(RoleButtonStyle(isSelected: selection == option))
            }
        }
        // Animates the transition between buttons
        .animation(.snappy, value: selection)
    }
}

struct RoleButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .white : .gray)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(borderView)
            .shadow(
                color: isSelected ? Color(hex: "2a5fff").opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                y: isSelected ? 4 : 0
            )
            // Slight scale effect when pressed
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            LinearGradient(
                colors: [Color(hex: "2a5fff"), Color(hex: "1a3dcc")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            Color.white.opacity(0.08)
        }
    }
    
    private var borderView: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                Color.white.opacity(isSelected ? 0.3 : 0.15),
                lineWidth: 1.5
            )
    }
}
