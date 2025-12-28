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
            LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.12), .black],
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
        .preferredColorScheme(.dark)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isSearchFocused ? .blue : .gray)
            
            TextField("Search name or role...", text: searchBinding)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .foregroundColor(.white)
                .accessibilityIdentifier("lookup.search")
            
            if !vm.query.isEmpty {
                Button { vm.setQuery("") } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.gray)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSearchFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1.5)
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
                    .tint(.blue)
                    .scaleEffect(1.2)
                Text("Sifting records...")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        } else if vm.results.isEmpty {
            placeholderState(icon: "person.crop.circle.badge.questionmark", text: "No employees found")
        } else {
            List(vm.results) { emp in
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
                .foregroundStyle(.white.opacity(0.2))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .padding(.top, 40)
        .transition(.opacity)
    }
}
