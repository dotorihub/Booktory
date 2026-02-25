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
        VStack {
            VStack {
                Text("Search")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Books, Authors...", text: $viewModel.query)
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
                            // Optional: keep focus so user can type again immediately
                            isSearchFocused = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Clear search text")
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
            .padding(.horizontal, 24)

            content
                .frame(maxWidth: .infinity)

            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            GuideView
        case .loading:
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, minHeight: 300)
        case .loaded(let books):
            if books.isEmpty {
                Text("No results")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(books) { book in
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
                            .padding(.vertical, 8)
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

    var GuideView: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.gray)
                .padding(24)

            Text("Search for your favorite books to add them to your library.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .padding()
        }
        .frame(height: 300, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 6
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
}

#Preview {
    SearchView()
}
