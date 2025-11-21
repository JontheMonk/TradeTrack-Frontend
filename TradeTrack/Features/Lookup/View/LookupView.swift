/// A searchable employee directory.
///
/// This view renders:
///   – A search bar bound to `LookupViewModel.query`
///   – State-dependent UI:
///       • Prompt for short queries
///       • Spinner during network requests
///       • Empty results feedback
///       • A list of matching employees
///   – Tappable result rows (`EmployeeCard`) that call
///     `vm.selectEmployee(_:)`, allowing the VM to drive navigation.
///
/// Architectural notes:
///   • The view owns its `LookupViewModel` via `@StateObject`.
///   • All networking and navigation decisions live in the VM.
///   • The view is a pure renderer with no business logic.
///   • Clear transitions between states ensure predictable updates.
///
/// This pattern aligns with modern SwiftUI:
///   – View: presentation
///   – ViewModel: async work + state + navigation
///   – Coordinator: handles actual route pushing


import SwiftUI

struct LookupView: View {
    @StateObject private var vm: LookupViewModel

    init(viewModel: LookupViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    private var searchBinding: Binding<String> {
        .init(get: { vm.query }, set: { vm.setQuery($0) })
    }

    private var hasMinQuery: Bool {
        vm.query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search employees (min 3 chars)…", text: searchBinding)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                if !vm.query.isEmpty {
                    Button { vm.setQuery("") } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)

            // States
            if !hasMinQuery {
                stateText("Enter at least 3 characters.")
            } else if vm.isLoading {
                ProgressView("Searching…").padding(.top, 8)
            } else if vm.results.isEmpty {
                stateText("No matches.")
            } else {
                // Results
                List(vm.results) { emp in
                    Button {
                        vm.selectEmployee(emp.employeeId)   // ← VM decides navigation
                    } label: {
                        EmployeeCard(employee: emp)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.top, 12)
        .navigationTitle("Employee Lookup")
        .animation(.default, value: vm.query)
        .animation(.default, value: vm.isLoading)
    }

    @ViewBuilder
    private func stateText(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary).padding(.top, 8)
    }
}
