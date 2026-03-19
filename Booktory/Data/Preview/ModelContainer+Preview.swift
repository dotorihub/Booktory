//
//  ModelContainer+Preview.swift
//  Booktory
//

import Foundation
import SwiftData

// MARK: - Preview용 in-memory 컨테이너

extension ModelContainer {

    /// SwiftUI Preview 환경에서 사용하는 인메모리 컨테이너.
    /// 앱 재시작 시 데이터가 초기화되므로 프로덕션에서는 사용하지 않는다.
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: LibraryBook.self, ReadingSession.self, Quote.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return container
    }

    /// Preview에 샘플 데이터가 포함된 컨테이너 반환
    @MainActor
    static var previewWithSampleData: ModelContainer {
        let container = preview
        let context = container.mainContext

        // 읽고 있는 책
        let book1 = LibraryBook(
            isbn: "9788934972464",
            title: "채식주의자",
            author: "한강",
            publisher: "창비",
            coverURL: "https://contents.kyobobook.co.kr/sih/fit-in/458x0/pdt/4808936434595.jpg",
            bookDescription: "한강의 장편소설.",
            status: .reading,
            startedAt: Date.now
        )
        let session1 = ReadingSession(
            libraryBookId: book1.id,
            startTime: Date(timeIntervalSinceNow: -3600),
            endTime: Date(timeIntervalSinceNow: -1800),
            duration: 1800
        )
        let session2 = ReadingSession(
            libraryBookId: book1.id,
            startTime: Date(timeIntervalSinceNow: -7200),
            endTime: Date(timeIntervalSinceNow: -5400),
            duration: 1800
        )
        session1.libraryBook = book1
        session2.libraryBook = book1

        // 읽고 싶은 책
        let book2 = LibraryBook(
            isbn: "9788937460449",
            title: "데미안",
            author: "헤르만 헤세",
            publisher: "민음사",
            coverURL: "https://contents.kyobobook.co.kr/sih/fit-in/400x0/pdt/9788937460449.jpg",
            bookDescription: "헤르만 헤세의 성장 소설.",
            status: .wantToRead
        )

        // 완독한 책
        let book3 = LibraryBook(
            isbn: "9791190090018",
            title: "불편한 편의점",
            author: "김호연",
            publisher: "나무옆의자",
            coverURL: "https://image.yes24.com/goods/99308021/XL",
            bookDescription: "편의점을 배경으로 한 따뜻한 이야기.",
            status: .completed,
            startedAt: Date(timeIntervalSinceNow: -86400 * 30),
            completedAt: Date(timeIntervalSinceNow: -86400 * 5)
        )

        // 샘플 Quote
        let quote1 = Quote(
            libraryBookId: book1.id,
            contentType: .text,
            textContent: "아무도 먹지 않는 밥상 위에 시든 미나리가 놓여 있었다."
        )
        quote1.libraryBook = book1

        context.insert(book1)
        context.insert(book2)
        context.insert(book3)
        context.insert(session1)
        context.insert(session2)
        context.insert(quote1)

        return container
    }
}
