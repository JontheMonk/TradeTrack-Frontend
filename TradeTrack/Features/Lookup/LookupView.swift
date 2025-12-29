import SwiftUI

struct LookupView: View {
    @StateObject private var viewModel: LookupViewModel
    @FocusState private var isSearchFocused: Bool

    init(viewModel: LookupViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var searchBinding: Binding<String> {
        .init(get: { viewModel.query }, set: { viewModel.setQuery($0) })
    }

    private var hasMinQuery: Bool {
        viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var body: some View {
        ZStack {
            backgroundView
            mainContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 20) {
            titleView
            searchBar
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, 8)
    }

    // MARK: - Background

    private var backgroundView: some View {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.1, blue: 0.12), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Title

    private var titleView: some View {
        HStack {
            Text("Directory")
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            searchIcon
            searchTextField
            clearButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(searchBarBackground)
        .padding(.horizontal)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchFocused)
    }

    private var searchIcon: some View {
        Image(systemName: "magnifyingglass")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(isSearchFocused ? .blue : .gray)
    }

    private var searchTextField: some View {
        TextField("Search name or role...", text: searchBinding)
            .focused($isSearchFocused)
            .submitLabel(.search)
            .foregroundColor(.white)
            .accessibilityIdentifier("lookup.search")
    }

    @ViewBuilder
    private var clearButton: some View {
        if !viewModel.query.isEmpty {
            Button { viewModel.setQuery("") } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.gray)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSearchFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1.5
                    )
            )
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if !hasMinQuery {
            placeholderState(
                icon: "person.text.rectangle",
                text: "Search at least 3 characters"
            )
        } else if viewModel.isLoading {
            loadingState
        } else if viewModel.results.isEmpty {
            placeholderState(
                icon: "person.crop.circle.badge.questionmark",
                text: "No employees found"
            )
        } else {
            resultsList
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.blue)
                .scaleEffect(1.2)
            Text("Sifting records...")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }

    private var resultsList: some View {
        List(viewModel.results) { employee in
            EmployeeCard(employee: employee)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("lookup.result.\(employee.employeeId)")
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    viewModel.selectEmployee(employee)
                }
        }
        .listStyle(.plain)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Helper Views

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
