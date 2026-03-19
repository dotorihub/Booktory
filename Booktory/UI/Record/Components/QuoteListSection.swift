//
//  QuoteListSection.swift
//  Booktory
//
//  기록 탭에서 최근 문장/이미지 기록을 표시하는 섹션.
//

import SwiftUI

struct QuoteListSection: View {
    let quotes: [Quote]

    /// 기록 탭에서 표시할 최대 개수
    private let displayLimit = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 문장 기록")
                .font(.headline)
                .padding(.horizontal)

            if quotes.isEmpty {
                Text("아직 문장 기록이 없어요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(quotes.prefix(displayLimit), id: \.id) { quote in
                    VStack(alignment: .leading, spacing: 2) {
                        // 책 제목 표시
                        if let bookTitle = quote.libraryBook?.title {
                            Text(bookTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                        QuoteRowView(quote: quote)
                    }
                }
            }
        }
    }
}
