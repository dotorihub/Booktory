//
//  LibraryBook.swift
//  Booktory
//

import Foundation
import SwiftData

// MARK: - ReadingStatus

enum ReadingStatus: String, Codable, CaseIterable {
    case wantToRead  // 읽고 싶은
    case reading     // 읽고 있는
    case completed   // 완독한

    var displayName: String {
        switch self {
        case .wantToRead: return "읽고 싶은"
        case .reading:    return "읽고 있는"
        case .completed:  return "완독한"
        }
    }
}

// MARK: - LibraryBook

@Model
final class LibraryBook {

    // MARK: Stored Properties

    var id: UUID
    var isbn: String
    var title: String
    var author: String
    var publisher: String
    var coverURL: String
    var bookDescription: String

    /// ReadingStatus를 String으로 저장 (#Predicate 호환성 보장)
    var statusRaw: String

    var addedAt: Date
    var startedAt: Date?
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.libraryBook)
    var sessions: [ReadingSession]

    // MARK: Computed Properties

    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRaw) ?? .wantToRead }
        set { statusRaw = newValue.rawValue }
    }

    /// 전체 독서 세션의 누적 시간 (초)
    var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    /// 가장 최근 세션의 종료 시각 (독서 탭 정렬 기준)
    var lastSessionDate: Date? {
        sessions.map(\.endTime).max()
    }

    // MARK: Init

    init(
        isbn: String,
        title: String,
        author: String,
        publisher: String,
        coverURL: String,
        bookDescription: String,
        status: ReadingStatus,
        addedAt: Date = .now,
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.coverURL = coverURL
        self.bookDescription = bookDescription
        self.statusRaw = status.rawValue
        self.addedAt = addedAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.sessions = []
    }
}

// MARK: - Book → LibraryBook 변환

extension LibraryBook {

    /// Naver Books API 검색 결과(Book)로부터 LibraryBook 생성
    static func create(from book: Book, status: ReadingStatus) -> LibraryBook {
        LibraryBook(
            isbn: book.isbn ?? book.id,
            title: book.title,
            author: book.author,
            publisher: book.publisher ?? "",
            coverURL: book.imageURL?.absoluteString ?? "",
            bookDescription: book.description ?? "",
            status: status,
            startedAt: status == .reading ? .now : nil
        )
    }
}
