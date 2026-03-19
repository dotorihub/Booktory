//
//  QuoteRowView.swift
//  Booktory
//
//  공용 Quote 행 — 텍스트 미리보기 또는 이미지 썸네일 + 날짜.
//

import SwiftUI

struct QuoteRowView: View {
    let quote: Quote

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            quoteContent
            Spacer()
            Text(quote.createdAt.formatted(
                .dateTime.month(.twoDigits).day(.twoDigits).hour().minute()
            ))
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var quoteContent: some View {
        switch quote.contentType {
        case .text:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "text.quote")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                Text(quote.textContent ?? "")
                    .font(.subheadline)
                    .lineLimit(3)
            }
        case .image:
            if let data = quote.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, height: 60)
            }
        }
    }
}
