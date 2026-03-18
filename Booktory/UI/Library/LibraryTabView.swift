//
//  LibraryTabView.swift
//  Booktory
//

import SwiftUI
import SwiftData

// MARK: - Public Entry Point

/// 환경 값에서 repository를 읽어 ViewModel을 생성하는 진입 뷰.
/// Preview에서는 viewModel을 직접 주입해 실제 DB 없이 동작한다.
struct LibraryTabView: View {
    @Environment(\.libraryRepository) private var repository
    private let previewViewModel: LibraryTabViewModel?

    init(viewModel: LibraryTabViewModel? = nil) {
        self.previewViewModel = viewModel
    }

    var body: some View {
        // @StateObject 생명주기 관리를 위해 내부 뷰에서 ViewModel을 소유.
        // LibraryTabView.body가 재평가될 때마다 새 인스턴스를 제안하지만,
        // @StateObject는 최초 1회만 초기화된다.
        LibraryTabContentView(
            viewModel: previewViewModel ?? LibraryTabViewModel(repository: repository)
        )
    }
}

// MARK: - Content View

private struct LibraryTabContentView: View {
    @StateObject var viewModel: LibraryTabViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LibraryFilterTabView(selectedFilter: Binding(
                    get: { viewModel.selectedFilter },
                    set: { filter in
                        Task { await viewModel.selectFilter(filter) }
                    }
                ))
                .padding(.top, 8)
                .background(alignment: .bottom) { Divider() }

                if viewModel.books.isEmpty && !viewModel.isLoading {
                    LibraryEmptyView(filter: viewModel.selectedFilter) {
                        coordinator.switchTab(to: .search)
                    }
                } else {
                    bookContent
                }
            }
            .navigationTitle("서재")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: LibraryBook.self) { book in
                LibraryDetailView(book: book)
            }
            .toolbar { toolbarContent }
            .alert("오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.loadBooks() }
        .onAppear { Task { await viewModel.loadBooks() } }
    }

    // MARK: - 콘텐츠 (그리드 / 리스트)

    @ViewBuilder
    private var bookContent: some View {
        switch viewModel.layoutStyle {
        case .grid:
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.books, id: \.id) { book in
                        NavigationLink(value: book) {
                            LibraryBookGridCard(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }

        case .list:
            List(viewModel.books, id: \.id) { book in
                NavigationLink(value: book) {
                    LibraryBookListRow(book: book)
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                SettingsPlaceholderView()
            } label: {
                Image(systemName: "gearshape")
                    .accessibilityLabel("설정")
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    viewModel.layoutStyle = .grid
                } label: {
                    Label("그리드", systemImage: "square.grid.2x2")
                }
                Button {
                    viewModel.layoutStyle = .list
                } label: {
                    Label("리스트", systemImage: "list.bullet")
                }
            } label: {
                Image(
                    systemName: viewModel.layoutStyle == .grid
                        ? "square.grid.2x2"
                        : "list.bullet"
                )
                .accessibilityLabel("레이아웃 변경")
            }
        }
    }
}

// MARK: - Preview

#Preview("그리드 - 전체") {
    let container = ModelContainer.previewWithSampleData
    let repo = DefaultLibraryRepository(context: container.mainContext)
    return LibraryTabView(viewModel: LibraryTabViewModel(repository: repo))
        .environmentObject(AppCoordinator())
        .modelContainer(container)
}

#Preview("리스트 - 읽고 있는") {
    let container = ModelContainer.previewWithSampleData
    let repo = DefaultLibraryRepository(context: container.mainContext)
    let vm = LibraryTabViewModel(repository: repo)
    vm.layoutStyle = .list
    vm.selectedFilter = .reading
    return LibraryTabView(viewModel: vm)
        .environmentObject(AppCoordinator())
        .modelContainer(container)
}

#Preview("Empty State - 전체") {
    LibraryTabView(viewModel: LibraryTabViewModel(repository: PreviewLibraryRepository.empty()))
        .environmentObject(AppCoordinator())
}
