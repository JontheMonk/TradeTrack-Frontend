import SwiftUI

struct LogInView: View {
    @StateObject var viewModel = LogInViewModel()
    @State private var animateBorder = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 🎥 Live camera feed
                CameraPreview(session: viewModel.getSession())
                    .edgesIgnoringSafeArea(.all)

                // 🕶 Dimmed overlay with face cutout
                Color.black.opacity(0.5)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.faceDetected)
                    .mask(
                        Rectangle()
                            .overlay(
                                GeometryReader { proxy in
                                    let width: CGFloat = 250
                                    let height: CGFloat = 350
                                    let x = (proxy.size.width - width) / 2
                                    let y = (proxy.size.height - height) / 2

                                    Rectangle()
                                        .frame(width: width, height: height)
                                        .offset(x: x, y: y)
                                        .blendMode(.destinationOut)
                                }
                            )
                    )
                    .compositingGroup()

                // 🌀 Animated border
                GeometryReader { proxy in
                    let width: CGFloat = 250
                    let height: CGFloat = 350
                    let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(borderGradient, lineWidth: 4)
                        .frame(width: width, height: height)
                        .position(center)
                        .shadow(color: borderShadow, radius: 10)
                        .scaleEffect(animateBorder && viewModel.faceDetected ? 1.05 : 1.0)
                        .animation(viewModel.faceDetected ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default, value: animateBorder)
                        .onChange(of: viewModel.faceDetected) {
                            animateBorder = viewModel.faceDetected
                        }

                }

                // 🟩 Welcome banner
                if let name = viewModel.matchName {
                    VStack {
                        Spacer()
                        Text("Welcome, \(name) 👋")
                            .font(.system(.title3, design: .rounded).bold())
                            .padding()
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(radius: 6)
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(), value: viewModel.matchName)
                    }
                }
            }
        }
    }

    // 🔁 Pulsing gradient border when face is detected
    private var borderGradient: LinearGradient {
        if viewModel.matchName != nil {
            return LinearGradient(colors: [.green, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if viewModel.faceDetected {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
        }
    }

    private var borderShadow: Color {
        if viewModel.matchName != nil {
            return .green.opacity(0.5)
        } else if viewModel.faceDetected {
            return .orange.opacity(0.5)
        } else {
            return .clear
        }
    }
}
