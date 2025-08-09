import SwiftUI

struct LookupView: View {
    @StateObject private var vm: LookupViewModel

    init(service: any EmployeeLookupServing, errorManager: ErrorManager) {
        let model = LookupViewModel(service: service, errorManager: errorManager)
        _vm = StateObject(wrappedValue: model)
    }

    private var searchBinding: Binding<String> {
        Binding(
            get: { vm.query },
            set: { vm.setQuery($0) }
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search employees (min 3 chars)…", text: searchBinding)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !vm.query.isEmpty {
                    Button(action: {
                        vm.setQuery("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal)

            if vm.query.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
                stateText("Enter at least 3 characters.")
            } else if vm.isLoading {
                ProgressView("Searching…").padding(.top, 8)
            } else if vm.results.isEmpty {
                stateText("No matches.")
            } else {
                List(vm.results) { emp in
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .imageScale(.large)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading) {
                            Text(emp.name).font(.headline)
                            Text("#\(emp.employeeId) • \(emp.role)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func stateText(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary).padding(.top, 8)
    }
}
