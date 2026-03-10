//
//  SearchView.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import SwiftUI

struct SearchView: View {
    @FocusState private var isSearchFocused: Bool
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                content
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .navigationTitle("검색")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
        }
    }

    // MARK: - 검색 바

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("책, 저자를 검색하세요", text: $viewModel.query)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isSearchFocused)
                .onChange(of: viewModel.query) { _ in
                    viewModel.searchWithDebounce()
                }
                .onSubmit {
                    viewModel.submitSearch()
                }
                .submitLabel(.search)

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clear()
                    isSearchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSearchFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isSearchFocused)
    }

    // MARK: - 상태별 콘텐츠

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            guideView
        case .loading:
            ProgressView("검색 중...")
                .frame(maxWidth: .infinity, minHeight: 300)
        case .loaded(let books):
            if books.isEmpty {
                Text("검색 결과가 없어요")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(books) { book in
                            NavigationLink(value: book) {
                                bookRow(book)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                Task {
                                    await viewModel.loadNextPageIfNeeded(currentItem: book)
                                }
                            }
                        }

                        if case .loading = viewModel.state {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                }
            }
        case .failed(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
        }
    }

    // MARK: - 책 행

    private func bookRow(_ book: Book) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: book.imageURL) { phase in
                switch phase {
                case .empty:
                    Color(.systemGray5)
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color(.systemGray5)
                @unknown default:
                    Color(.systemGray5)
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let publisher = book.publisher {
                    Text(publisher)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 가이드 뷰

    private var guideView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 4)

            Text("읽고 싶은 책을 검색해 보세요")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .center)
        .padding(.horizontal, 32)
    }
}

#Preview {
    SearchView()
        .environmentObject(AppCoordinator())
}
