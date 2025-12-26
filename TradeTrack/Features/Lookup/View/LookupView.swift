import SwiftUI

struct LookupView: View {
    @StateObject private var vm: LookupViewModel
    @FocusState private var isSearchFocused: Bool

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
        ZStack {
            LinearGradient(colors: [Color(.systemGroupedBackground), Color(.systemBackground)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                searchBar
                
                contentArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Directory")
        .navigationBarTitleDisplayMode(.large)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isSearchFocused ? .blue : .secondary)
            
            TextField("Search name or role...", text: searchBinding)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .accessibilityIdentifier("lookup.search")
            
            if !vm.query.isEmpty {
                Button { vm.setQuery("") } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSearchFocused ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        }
        .padding(.horizontal)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchFocused)
    }

    @ViewBuilder
    private var contentArea: some View {
        if !hasMinQuery {
            placeholderState(icon: "person.text.rectangle", text: "Search at least 3 characters")
        } else if vm.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Sifting records...").font(.caption).foregroundStyle(.secondary)
            }
        } else if vm.results.isEmpty {
            placeholderState(icon: "person.crop.circle.badge.questionmark", text: "No employees found")
        } else {
            List(vm.results) { emp in
                // FIXED: Flattening the card so XCUI sees one "Button"
                EmployeeCard(employee: emp)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("lookup.result.\(emp.employeeId)")
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture {
                        vm.selectEmployee(emp.employeeId)
                    }
            }
            .listStyle(.plain)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func placeholderState(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
        .transition(.opacity)
    }
}
