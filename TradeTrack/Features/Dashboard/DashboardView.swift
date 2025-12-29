import SwiftUI
import TradeTrackCore

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @State private var elapsedTime: TimeInterval = 0
    @State private var showSignOutAlert = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            backgroundView
            mainContent
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                signOutButton
            }
            if viewModel.isAdmin {
                ToolbarItem(placement: .topBarLeading) {
                    registerButton
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("", isPresented: $showSignOutAlert, titleVisibility: .hidden) {
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You'll need to verify your face again to clock in.")
        }
        .task { await viewModel.onAppear() }
        .onChange(of: viewModel.clockInTime) { _, newTime in
            if let time = newTime {
                elapsedTime = Date().timeIntervalSince(time)
            } else {
                elapsedTime = 0
            }
        }
    }

    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [Color(hex: "0f0f14"), Color(hex: "1a1a24")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer()
            statusRingView
            Spacer()
            clockButtonView
        }
    }

    // MARK: - Status Ring
    
    private var statusRingView: some View {
        ZStack {
            outerGlow
            ring
            innerContent
        }
    }
    
    private var outerGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        (viewModel.isClockedIn ? Color.green : Color.gray).opacity(0.3),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 80,
                    endRadius: 150
                )
            )
            .frame(width: 300, height: 300)
    }
    
    private var ring: some View {
        Circle()
            .stroke(
                viewModel.isClockedIn ? Color.green : Color(hex: "2a2a35"),
                lineWidth: 4
            )
            .frame(width: 250, height: 250)
    }
    
    private var innerContent: some View {
        VStack(spacing: 8) {
            statusText
            elapsedTimeView
            clockInTimeView
        }
    }
    
    private var statusText: some View {
        Text(viewModel.isClockedIn ? "ON SHIFT" : "OFF SHIFT")
            .accessibilityIdentifier("dashboard.status")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .tracking(3)
            .foregroundColor(viewModel.isClockedIn ? .green : .gray)
    }
    
    @ViewBuilder
    private var elapsedTimeView: some View {
        if viewModel.isClockedIn, let startTime = viewModel.clockInTime {
            Text(formatElapsed(elapsedTime))
                .font(.system(size: 42, weight: .thin, design: .monospaced))
                .foregroundColor(.white)
                .onReceive(timer) { _ in
                    elapsedTime = Date().timeIntervalSince(startTime)
                }
        } else {
            Text("--:--:--")
                .font(.system(size: 42, weight: .thin, design: .monospaced))
                .foregroundColor(Color(hex: "3a3a45"))
        }
    }
    
    @ViewBuilder
    private var clockInTimeView: some View {
        if let time = viewModel.clockInTime {
            Text("since \(time.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Clock Button
    
    private var clockButtonView: some View {
        Button {
            Task { await viewModel.toggleClock() }
        } label: {
            Text(viewModel.isClockedIn ? "CLOCK OUT" : "CLOCK IN")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(viewModel.isClockedIn ? Color(hex: "e63946") : Color.green)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1)
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
        .accessibilityIdentifier("dashboard.clock_button")
    }

    // MARK: - Toolbar Items
    
    private var signOutButton: some View {
        Button { showSignOutAlert = true } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundColor(.gray)
                .font(.system(size: 22))
        }
    }
    
    private var registerButton: some View {
        Button { viewModel.goToRegister() } label: {
            Image(systemName: "person.badge.plus")
                .foregroundColor(.gray)
                .font(.system(size: 22))
        }
    }

    // MARK: - Helpers
    
    private func formatElapsed(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
