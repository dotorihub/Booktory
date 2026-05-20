//
//  ReadingTabView.swift
//  Booktory
//
//  독서 탭 — 읽고 있는 책 목록 + 타이머 진입점.
//  reading 상태 책을 카드로 표시하고, [이어 읽기]로 타이머를 오픈한다.
//

import SwiftUI
import SwiftData

// MARK: - Public Entry Point

/// 환경 값에서 repository를 읽어 ViewModel을 생성하는 진입 뷰.
/// Preview에서는 viewModel을 직접 주입해 실제 DB 없이 동작한다.
struct ReadingTabView: View {
    @Environment(\.libraryRepository) private var repository
    private let previewViewModel: ReadingTabViewModel?

    init(viewModel: ReadingTabViewModel? = nil) {
        self.previewViewModel = viewModel
    }

    var body: some View {
        ReadingTabContentView(
            viewModel: previewViewModel ?? ReadingTabViewModel(repository: repository)
        )
    }
}

// MARK: - Content View

private struct ReadingTabContentView: View {
    @StateObject var viewModel: ReadingTabViewModel
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.libraryRepository) private var repository
    @State private var isSearchPresented = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.books.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.books.isEmpty {
                    ReadingEmptyView {
                        isSearchPresented = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.books, id: \.id) { book in
                                ReadingBookCard(
                                    book: book,
                                    totalSeconds: viewModel.totalReadingSeconds(for: book),
                                    onResume: {
                                        viewModel.selectedBook = book
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("독서")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    fakeSearchBar
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isSearchPresented) {
                SearchView()
            }
            .task {
                viewModel.pendingAutoOpenId = coordinator.pendingAutoOpenBookId
                await viewModel.loadBooks()
            }
            .fullScreenCover(item: $viewModel.selectedBook, onDismiss: {
                Task { await viewModel.loadBooks() }
            }) { book in
                TimerView(book: book, repository: repository)
            }
            .onChange(of: coordinator.pendingAutoOpenBookId) { _, bookId in
                guard let bookId else { return }
                if let book = viewModel.books.first(where: { $0.id == bookId }) {
                    viewModel.selectedBook = book
                } else {
                    viewModel.pendingAutoOpenId = bookId
                    Task { await viewModel.loadBooks() }
                }
                coordinator.pendingAutoOpenBookId = nil
            }
            .alert("오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Subviews

extension ReadingTabContentView {
    private var fakeSearchBar: some View {
        Button {
            isSearchPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text("읽고 싶은 책을 검색해 보세요")
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("책 있는 경우") {
    let container = ModelContainer.previewWithSampleData
    let repo = DefaultLibraryRepository(context: container.mainContext)
    return ReadingTabView(viewModel: ReadingTabViewModel(repository: repo))
        .environmentObject(AppCoordinator())
        .modelContainer(container)
}

#Preview("Empty State") {
    ReadingTabView(viewModel: ReadingTabViewModel(
        repository: PreviewLibraryRepository()
    ))
    .environmentObject(AppCoordinator())
}
