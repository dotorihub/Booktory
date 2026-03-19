//
//  LibraryBook.swift
//  Booktory
//

import Foundation
import SwiftData

@Model
final class LibraryBook {
    var id: UUID
    var isbn: String
    var title: String
    var author: String
    var publisher: String
    var coverURL: String
    var bookDescription: String
    var status: ReadingStatus
    var addedAt: Date
    var startedAt: Date?
    var completedAt: Date?
    /// 책 고유 컬러 인덱스 (BookColor.allCases.count 순환 배정)
    var colorIndex: Int = 0

    @Relationship(deleteRule: .cascade)
    var sessions: [ReadingSession] = []

    init(
        isbn: String,
        title: String,
        author: String,
        publisher: String,
        coverURL: String,
        bookDescription: String,
        status: ReadingStatus,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        colorIndex: Int = 0
    ) {
        self.id = UUID()
        self.isbn = isbn
        self.title = title
        self.author = author
        self.publisher = publisher
        self.coverURL = coverURL
        self.bookDescription = bookDescription
        self.status = status
        self.addedAt = Date()
        self.startedAt = startedAt ?? (status == .reading ? Date() : nil)
        self.completedAt = completedAt ?? nil
        self.colorIndex = colorIndex
    }
}

// MARK: - Computed (extension으로 분리하여 @Model 매크로 간섭 방지)

extension LibraryBook {
    /// 할당된 BookColor
    var bookColor: BookColor {
        BookColor.from(index: colorIndex)
    }
}
