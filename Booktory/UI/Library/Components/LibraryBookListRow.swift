//
//  LibraryBookListRow.swift
//  Booktory
//

import SwiftUI

struct LibraryBookListRow: View {
    let book: LibraryBook

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            coverImage
            textInfo
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var coverImage: some View {
        AsyncImage(url: URL(string: book.coverURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "book.closed")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundStyle(.quaternary)
            case .empty:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(ProgressView().tint(.secondary))
            @unknown default:
                Color(.tertiarySystemBackground)
            }
        }
        .frame(width: 60, height: 60)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(4)
    }

    private var textInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title)
                .lineLimit(2)
                .font(.body.weight(.medium))
            Text(book.author)
                .lineLimit(1)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List(LibraryBook.previewItems) { book in
        LibraryBookListRow(book: book)
    }
    .listStyle(.plain)
}
