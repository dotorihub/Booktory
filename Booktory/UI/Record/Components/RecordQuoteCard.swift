//
//  RecordQuoteCard.swift
//  Booktory
//
//  기록 탭의 문장 카드. 파스텔 배경 + 중앙 정렬 텍스트 + 하단 책 제목.
//

import SwiftUI

struct RecordQuoteCard: View {
    let quote: Quote

    // 미색 계열 파스텔. id 해시로 카드마다 고정 색상 부여
    private static let pastelColors: [Color] = [
        Color(red: 0.99, green: 0.98, blue: 0.94), // 크림
        Color(red: 0.99, green: 0.96, blue: 0.94), // 피치
        Color(red: 0.94, green: 0.98, blue: 0.95), // 민트
        Color(red: 0.96, green: 0.95, blue: 0.99), // 라벤더
        Color(red: 0.94, green: 0.97, blue: 0.99), // 스카이
        Color(red: 0.99, green: 0.95, blue: 0.96), // 로즈
    ]

    private var backgroundColor: Color {
        let seed = abs(quote.id.hashValue)
        return Self.pastelColors[seed % Self.pastelColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(quote.textContent ?? "")
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 52)

            if let title = quote.libraryBook?.title {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
        .padding(.bottom, 20)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 1, x: -1, y: -1)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 2, y: 4)
    }
}
