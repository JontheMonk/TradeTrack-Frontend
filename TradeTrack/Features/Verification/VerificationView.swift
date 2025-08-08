import SwiftUI

struct VerificationView: View {
    @StateObject var viewModel = try! FaceVerificationViewModel()
    @EnvironmentObject var errorManager: ErrorManager


    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack {
                Spacer()

                ZStack {
                    CameraPreview(session: viewModel.getSession())
                        .clipShape(Circle())
                        .frame(width: 250, height: 250)
                        .overlay(
                            Circle()
                                .strokeBorder(circleBorderColor, lineWidth: 4)
                                .shadow(color: circleShadowColor, radius: 10)
                        )
                        .scaleEffect(viewModel.verificationState == .processing ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.verificationState == .processing)

                    if case .matched(let name) = viewModel.verificationState {
                        VStack {
                            Spacer()
                            Text("✅ Welcome, \(name)")
                                .font(.headline)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .shadow(radius: 4)
                        }
                        .frame(height: 250)
                    }
                }

                Spacer()

                // 🟠 State Message
                Text(statusText)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.bottom)

                // 🔴 Error banner (if any)
                ErrorBannerView()
                    .padding(.top, 8)
            }
        }
    }

    private var circleBorderColor: Color {
        switch viewModel.verificationState {
        case .processing:
            return .orange
        case .matched:
            return .green
        default:
            return .gray.opacity(0.3)
        }
    }

    private var circleShadowColor: Color {
        switch viewModel.verificationState {
        case .processing:
            return .orange.opacity(0.5)
        case .matched:
            return .green.opacity(0.5)
        default:
            return .clear
        }
    }

    private var statusText: String {
        switch viewModel.verificationState {
        case .detecting:
            return "Looking for a face..."
        case .processing:
            return "Processing..."
        case .matched:
            return "Face matched!"
        }
    }
}
