import SwiftUI
import TradeTrackCore

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Status display
            VStack(spacing: 8) {
                Text(viewModel.isClockedIn ? "Clocked In" : "Clocked Out")
                    .font(.title)
                    .fontWeight(.semibold)
                
                if let time = viewModel.clockInTime {
                    Text("Since \(time.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Clock toggle button
            Button {
                Task { await viewModel.toggleClock() }
            } label: {
                Text(viewModel.isClockedIn ? "Clock Out" : "Clock In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isClockedIn ? .red : .green)
            .disabled(viewModel.isLoading)
            
            Spacer()
        }
        .padding()
        .task { await viewModel.onAppear() }
    }
}
