import SwiftUI
import Vision

struct VerificationView: View {
    
    // MARK: - Dependencies
    @StateObject private var vm: VerificationViewModel
    
    // Pulse animation for the inactive state
    @State private var pulseScale: CGFloat = 1.0

    init(viewModel: VerificationViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Dark obsidian background
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 48) {
                headerSection
                
                // MARK: - Biometric Interface
                ZStack {
                    cameraPreviewLayer
                    
                    // The Ring: Logic depends ONLY on collectionProgress
                    // It stays visible as long as we aren't successfully matched.
                    if !isMatched {
                        ZStack {
                            // Static background track
                            Circle()
                                .stroke(Color.white.opacity(0.05), lineWidth: 8)
                            
                            // Dynamic progress fill
                            Circle()
                                .trim(from: 0, to: vm.collectionProgress)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.cyan, .blue, .purple, .cyan]),
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                // Smooths out the jumps in progress updates
                                .animation(.easeOut(duration: 0.2), value: vm.collectionProgress)
                        }
                        .frame(width: 296, height: 296)
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                    }
                    
                    if isMatched {
                        successIcon
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 280, height: 280)
                
                statusIndicator
                
                Spacer()
            }
            .padding(.top, 60)
        }
        .task { await vm.start() }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.04
            }
        }
    }
}

// MARK: - View Components

private extension VerificationView {
    
    var isMatched: Bool {
        if case .matched = vm.state { return true }
        return false
    }

    var headerSection: some View {
        VStack(spacing: 10) {
            Text("Biometric Verification")
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(.white)
            Text("Position your face within the frame")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    var cameraPreviewLayer: some View {
        CameraPreview(session: vm.session)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 2)
                    .scaleEffect(pulseScale)
            )
            .grayscale(isMatched ? 1.0 : 0.0)
            .opacity(isMatched ? 0.4 : 1.0)
    }

    var successIcon: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 100))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, .green)
            .shadow(color: .green.opacity(0.4), radius: 20)
    }
    
    var statusIndicator: some View {
        HStack(spacing: 12) {
            if vm.state == .processing {
                ProgressView().tint(.white)
            }
            Text(statusText)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
                .accessibilityIdentifier("verification.status_indicator")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 32)
        .background(statusBackgroundColor)
        .clipShape(Capsule())
        .animation(.spring(), value: vm.state)
    }
}

// MARK: - Computed Helpers

private extension VerificationView {
    var statusText: String {
        switch vm.state {
        case .detecting:
            return vm.collectionProgress > 0.05 ? "Analyzing..." : "Align Face"
        case .processing:
            return "Verifying Identity"
        case .matched(let name):
            return "Welcome, \(name)"
        }
    }
    
    var statusBackgroundColor: Color {
        switch vm.state {
        case .detecting:
            return .white.opacity(0.12)
        case .processing:
            return .blue.opacity(0.45)
        case .matched:
            return .green.opacity(0.5)
        }
    }
}
