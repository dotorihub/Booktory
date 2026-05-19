//
//  QuoteRowView.swift
//  Booktory
//
//  공용 Quote 행 — 텍스트 미리보기 + 날짜.
//

import SwiftUI

struct QuoteRowView: View {
    let quote: Quote

    /// v1 잔여 데이터(이미지만 있던 quote)는 textContent가 nil이라 빈 행이 됨 — 표시 생략.
    private var displayText: String? {
        guard let text = quote.textContent?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return nil }
        return text
    }

    var body: some View {
        if let text = displayText {
            HStack(alignment: .top, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.quote")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    Text(text)
                        .font(.subheadline)
                        .lineLimit(3)
                }
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
    }
}
