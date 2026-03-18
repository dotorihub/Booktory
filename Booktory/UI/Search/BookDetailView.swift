//
//  BookDetailView.swift
//  Booktory
//

import SwiftUI

// MARK: - Public Entry Point

/// 환경에서 repository / coordinator를 읽어 ViewModel을 생성한다.
struct BookDetailView: View {
    let book: Book
    @Environment(\.libraryRepository) private var repository
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        BookDetailContentView(
            viewModel: BookDetailViewModel(
                book: book,
                repository: repository,
                coordinator: coordinator
            )
        )
    }
}

// MARK: - Content View

private struct BookDetailContentView: View {
    @StateObject var viewModel: BookDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                coverImage
                bookInfo
                Divider()
                    .padding(.horizontal)
                descriptionSection
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { actionButtons }
        .task { await viewModel.loadLibraryState() }
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 책 표지

    private var coverImage: some View {
        AsyncImage(url: viewModel.book.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "book.closed.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.quaternary)
            case .empty:
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: 160)
        .aspectRatio(contentMode: .fit)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        .padding(.horizontal)
    }

    // MARK: - 제목 / 저자 / 출판사

    private var bookInfo: some View {
        VStack(spacing: 6) {
            Text(viewModel.book.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Text(viewModel.book.author)
                if let publisher = viewModel.book.publisher {
                    Text("·")
                    Text(publisher)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    // MARK: - 책 소개

    @ViewBuilder
    private var descriptionSection: some View {
        if let description = viewModel.book.description, !description.isEmpty {
            ExpandableDescriptionView(text: description)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    // MARK: - 액션 버튼 (하단 고정)

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if viewModel.showWishlistButton {
                Button {
                    Task { await viewModel.toggleWishlist() }
                } label: {
                    Image(systemName: viewModel.wishlistIconName)
                        .imageScale(.large)
                }
                .buttonStyle(.bordered)
                .tint(.primary)
                .aspectRatio(1, contentMode: .fit)
                .accessibilityLabel(viewModel.wishlistAccessibilityLabel)
                .disabled(viewModel.isLoading)
            }

            Button {
                Task { await viewModel.readNow() }
            } label: {
                Text(viewModel.readNowButtonLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isReadNowEnabled || viewModel.isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}

// MARK: - Preview

#Preview("서재에 없는 책") {
    NavigationStack {
        BookDetailView(book: .preview)
    }
    .environmentObject(AppCoordinator())
}

#Preview("읽고 싶은 책") {
    let repo = PreviewLibraryRepository()
    try? repo.add(LibraryBook(from: .preview, status: .wantToRead))
    return NavigationStack {
        BookDetailView(book: .preview)
            .environment(\.libraryRepository, repo)
    }
    .environmentObject(AppCoordinator())
}

#Preview("읽고 있는 책") {
    let repo = PreviewLibraryRepository()
    try? repo.add(LibraryBook(from: .preview, status: .reading))
    return NavigationStack {
        BookDetailView(book: .preview)
            .environment(\.libraryRepository, repo)
    }
    .environmentObject(AppCoordinator())
}
