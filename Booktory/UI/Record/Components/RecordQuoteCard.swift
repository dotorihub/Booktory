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
        Color(red: 0.99, green: 0.97, blue: 0.88), // 크림
        Color(red: 0.98, green: 0.93, blue: 0.89), // 피치
        Color(red: 0.90, green: 0.95, blue: 0.91), // 민트
        Color(red: 0.93, green: 0.91, blue: 0.97), // 라벤더
        Color(red: 0.89, green: 0.94, blue: 0.99), // 스카이
        Color(red: 0.99, green: 0.92, blue: 0.94), // 로즈
    ]

    private var backgroundColor: Color {
        let seed = abs(quote.id.hashValue)
        return Self.pastelColors[seed % Self.pastelColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(quote.textContent ?? "")
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            if let title = quote.libraryBook?.title {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 1, x: -1, y: -1)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 2, y: 4)
    }
}

#Preview {
    let book = LibraryBook(
        isbn: "9791162540145",
        title: "클린 코드",
        author: "로버트 C. 마틴",
        publisher: "인사이트",
        coverURL: "",
        bookDescription: "",
        status: .reading
    )
    let quote = Quote(libraryBookId: book.id, textContent: "깨끗한 코드는 잘 쓴 문장처럼 읽혀야 한다.")
    quote.libraryBook = book

    RecordQuoteCard(quote: quote)
        .padding()
}
