//
//  LibraryBook+Preview.swift
//  Booktory
//
//  Preview 및 UI 개발용 더미 데이터.
//  검색 탭 → 서재 추가 기능 개발 전까지 임시 사용.
//

import Foundation

extension LibraryBook {

    /// Preview용 더미 LibraryBook 배열 (다양한 상태 포함)
    static var previewItems: [LibraryBook] {
        [
            LibraryBook(
                isbn: "9791162540145",
                title: "클린 코드",
                author: "로버트 C. 마틴",
                publisher: "인사이트",
                coverURL: "",
                bookDescription: "애자일 소프트웨어 장인 정신",
                status: .reading
            ),
            LibraryBook(
                isbn: "9791185475219",
                title: "함께 자라기",
                author: "김창준",
                publisher: "인사이트",
                coverURL: "",
                bookDescription: "애자일로 가는 길",
                status: .reading
            ),
            LibraryBook(
                isbn: "9788966261208",
                title: "도메인 주도 설계",
                author: "에릭 에반스",
                publisher: "위키북스",
                coverURL: "",
                bookDescription: "소프트웨어의 복잡성을 다루는 지혜",
                status: .completed
            ),
            LibraryBook(
                isbn: "9791158391690",
                title: "실용주의 프로그래머",
                author: "앤드류 헌트, 데이비드 토마스",
                publisher: "인사이트",
                coverURL: "",
                bookDescription: "20주년 기념판",
                status: .completed
            ),
            LibraryBook(
                isbn: "9788966261154",
                title: "테스트 주도 개발",
                author: "켄트 벡",
                publisher: "인사이트",
                coverURL: "",
                bookDescription: "TDD 실천법과 패턴",
                status: .wantToRead
            ),
            LibraryBook(
                isbn: "9791191866018",
                title: "소프트웨어 장인",
                author: "산드로 만쿠소",
                publisher: "길벗",
                coverURL: "",
                bookDescription: "프로페셔널리즘, 실용주의, 자부심",
                status: .wantToRead
            ),
        ]
    }
}

extension PreviewLibraryRepository {

    /// 다양한 상태의 더미 책이 채워진 Repository
    static func populated() -> PreviewLibraryRepository {
        let repo = PreviewLibraryRepository()
        for book in LibraryBook.previewItems {
            try? repo.add(book)
        }
        return repo
    }

    /// 독서 세션이 포함된 Repository (기록 탭 Preview용)
    static func populatedWithSessions() -> PreviewLibraryRepository {
        let repo = PreviewLibraryRepository()
        let books = LibraryBook.previewItems
        for book in books {
            try? repo.add(book)
        }

        let calendar = Calendar.current
        let now = Date()

        // 읽고 있는 책(클린 코드)에 이번 주 세션 추가
        if let readingBook = books.first(where: { $0.status == .reading }) {
            for dayOffset in [0, -1, -2, -4] {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                let durations: [TimeInterval] = [1800, 3600, 5400, 2700]
                let duration = durations[abs(dayOffset) % durations.count]
                let session = ReadingSession(
                    libraryBookId: readingBook.id,
                    startTime: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: date) ?? date,
                    endTime: calendar.date(bySettingHour: 21, minute: Int(duration / 60), second: 0, of: date) ?? date,
                    duration: duration
                )
                try? repo.addSession(session, to: readingBook.id)
            }
        }

        // 읽고 있는 책(함께 자라기)에 지난 주 세션 추가
        if let secondBook = books.first(where: { $0.title == "함께 자라기" }) {
            for dayOffset in [-7, -9, -14, -20] {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                let session = ReadingSession(
                    libraryBookId: secondBook.id,
                    startTime: calendar.date(bySettingHour: 20, minute: 30, second: 0, of: date) ?? date,
                    endTime: calendar.date(bySettingHour: 21, minute: 15, second: 0, of: date) ?? date,
                    duration: 2700
                )
                try? repo.addSession(session, to: secondBook.id)
            }
        }

        return repo
    }

    /// Empty State 확인용 빈 Repository
    static func empty() -> PreviewLibraryRepository {
        PreviewLibraryRepository()
    }
}
