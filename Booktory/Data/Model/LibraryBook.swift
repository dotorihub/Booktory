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

    @Relationship(deleteRule: .cascade)
    var sessions: [ReadingSession] = []

    init(
        isbn: String,
        title: String,
        author: String,
        publisher: String,
        coverURL: String,
        bookDescription: String,
        status: ReadingStatus
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
        self.startedAt = status == .reading ? Date() : nil
        self.completedAt = nil
    }
}
