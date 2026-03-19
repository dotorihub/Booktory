//
//  DayBookCard.swift
//  Booktory
//
//  선택된 날짜의 책별 독서 요약 카드.
//  컬러 뱃지 + 책 표지 + 제목 + 해당 날 읽은 시간을 표시한다.
//

import SwiftUI

struct DayBookCard: View {
    let summary: DayBookSummary

    var body: some View {
        HStack(spacing: 12) {
            // 컬러 뱃지
            Circle()
                .fill(summary.bookColor.color)
                .frame(width: 10, height: 10)

            // 책 표지
            AsyncImage(url: URL(string: summary.coverURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    coverPlaceholder
                case .empty:
                    coverPlaceholder
                @unknown default:
                    coverPlaceholder
                }
            }
            .frame(width: 40, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // 제목 + 독서 시간
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(DurationFormatter.format(summary.totalDuration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.paperGray)
            .overlay(
                Image(systemName: "book.closed.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            )
    }
}

#Preview {
    VStack {
        DayBookCard(summary: DayBookSummary(
            id: UUID(),
            title: "클린 코드",
            coverURL: "",
            bookColor: .red,
            totalDuration: 5400
        ))
        DayBookCard(summary: DayBookSummary(
            id: UUID(),
            title: "함께 자라기",
            coverURL: "",
            bookColor: .orange,
            totalDuration: 2700
        ))
    }
}
