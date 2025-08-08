import SwiftUI

struct ErrorBannerView: View {
    @EnvironmentObject var errorManager: ErrorManager

    var body: some View {
        VStack {
            if let error = errorManager.currentError {
                Text(userMessage(for: error.code))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding()
    }
}
