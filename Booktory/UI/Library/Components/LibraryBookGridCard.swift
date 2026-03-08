//
//  LibraryBookGridCard.swift
//  Booktory
//

import SwiftUI

struct LibraryBookGridCard: View {
    let book: LibraryBook

    var body: some View {
        AsyncImage(url: URL(string: book.coverURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                fallbackView
            case .empty:
                placeholderView
            @unknown default:
                placeholderView
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(6)
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.tertiarySystemBackground))
            .overlay(
                ProgressView()
                    .tint(.secondary)
            )
    }

    private var fallbackView: some View {
        Image(systemName: "book.closed")
            .resizable()
            .scaledToFit()
            .padding(20)
            .foregroundStyle(.quaternary)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        LibraryBookGridCard(book: .previewItems[0])
        LibraryBookGridCard(book: .previewItems[1])
        LibraryBookGridCard(book: .previewItems[2])
        LibraryBookGridCard(book: .previewItems[3])
    }
    .padding()
}
