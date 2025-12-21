import SwiftUI

/// A high-fidelity face verification screen featuring a dynamic scanning interface.
///
/// This view visualizes the multi-stage verification process:
/// 1. **Detection:** A pulsing laser line scans the camera feed.
/// 2. **Collection:** A circular progress ring fills as the system gathers high-quality frames.
/// 3. **Verification:** A loading state while the network request is in flight.
/// 4. **Success:** A distinct visual confirmation upon match.
struct VerificationView: View {
    
    // MARK: - Dependencies
    
    /// The view model managing the biometric pipeline and state.
    @StateObject private var vm: VerificationViewModel
    
    /// Internal state to drive the purely visual "laser" animation.
    @State private var laserOffset: CGFloat = -120

    init(viewModel: VerificationViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Modern dark aesthetic
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                headerSection
                
                // MARK: - Camera & Scanning Interface
                ZStack {
                    cameraPreviewLayer
                    
                    // The "Scanning Ring" tied to ViewModel progress
                    scanningProgressRing
                    
                    // The visual "Laser" line
                    if vm.state == .detecting {
                        scanningLaserEffect
                    }
                }
                .frame(width: 280, height: 280)
                
                statusIndicator
                
                Spacer()
            }
            .padding(.top, 60)
        }
        // MARK: - Lifecycle
        .task { await vm.start() }
        .onDisappear {
            Task { await vm.stop() }
        }
    }
}

// MARK: - View Components

private extension VerificationView {
    
    /// The title section of the verification screen.
    var headerSection: some View {
        VStack(spacing: 8) {
            Text("Identity Verification")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Position your face within the circle")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    /// The circular camera feed with a subtle glow.
    var cameraPreviewLayer: some View {
        CameraPreview(session: vm.session)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineWidth: 4)
            )
            .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 0)
    }
    
    /// A progress ring that fills as the 0.8s collection window completes.
    var scanningProgressRing: some View {
        Circle()
            .trim(from: 0, to: vm.collectionProgress)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [.cyan, .blue, .purple, .cyan]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 6, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 0.1), value: vm.collectionProgress)
            .frame(width: 292, height: 292) // Slightly larger than camera
    }
    
    /// A visual "Laser" effect that moves up and down during detection.
    var scanningLaserEffect: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .cyan.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 240, height: 40)
            .offset(y: laserOffset)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    laserOffset = 120
                }
            }
    }
    
    /// A bottom status bubble that changes color based on the verification state.
    var statusIndicator: some View {
        HStack(spacing: 12) {
            if vm.state == .processing {
                ProgressView()
                    .tint(.white)
            }
            
            Text(statusText)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .background(statusBackgroundColor)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10)
        .animation(.spring(), value: vm.state)
    }
}

// MARK: - Computed Helpers

private extension VerificationView {
    var statusText: String {
        switch vm.state {
        case .detecting: return "Scanning..."
        case .processing: return "Verifying Identity"
        case .matched(let name): return "Welcome, \(name)"
        }
    }
    
    var statusBackgroundColor: Color {
        switch vm.state {
        case .detecting: return .blue.opacity(0.3)
        case .processing: return .orange.opacity(0.5)
        case .matched: return .green.opacity(0.6)
        }
    }
}
