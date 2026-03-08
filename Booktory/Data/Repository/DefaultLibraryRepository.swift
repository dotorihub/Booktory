//
//  DefaultLibraryRepository.swift
//  Booktory
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.dotorihub.Booktory", category: "LibraryRepository")

final class DefaultLibraryRepository: LibraryRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - LibraryBook 조회

    func fetchAll() throws -> [LibraryBook] {
        let descriptor = FetchDescriptor<LibraryBook>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchBy(status: ReadingStatus) throws -> [LibraryBook] {
        let descriptor = FetchDescriptor<LibraryBook>(
            predicate: #Predicate { $0.status == status },
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchBy(isbn: String) throws -> LibraryBook? {
        let descriptor = FetchDescriptor<LibraryBook>(
            predicate: #Predicate { $0.isbn == isbn }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - LibraryBook 쓰기

    func add(_ book: LibraryBook) throws {
        guard (try? fetchBy(isbn: book.isbn)) == nil else {
            throw LibraryRepositoryError.duplicateISBN(book.isbn)
        }
        context.insert(book)
        try context.save()
    }

    func updateStatus(id: UUID, to status: ReadingStatus) throws {
        guard let book = try fetchBookBy(id: id) else {
            throw LibraryRepositoryError.bookNotFound(id)
        }
        book.status = status
        switch status {
        case .reading where book.startedAt == nil:
            book.startedAt = Date()
        case .completed:
            book.completedAt = Date()
        default:
            break
        }
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let book = try fetchBookBy(id: id) else {
            throw LibraryRepositoryError.bookNotFound(id)
        }
        context.delete(book)
        try context.save()
    }

    // MARK: - ReadingSession

    func addSession(_ session: ReadingSession, to bookId: UUID) throws {
        guard let book = try fetchBookBy(id: bookId) else {
            throw LibraryRepositoryError.bookNotFound(bookId)
        }
        book.sessions.append(session)
        context.insert(session)
        try context.save()
    }

    func fetchSessions(for bookId: UUID) throws -> [ReadingSession] {
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.libraryBookId == bookId },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Private

    private func fetchBookBy(id: UUID) throws -> LibraryBook? {
        let descriptor = FetchDescriptor<LibraryBook>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
}

// MARK: - Errors

enum LibraryRepositoryError: LocalizedError {
    case duplicateISBN(String)
    case bookNotFound(UUID)

    var errorDescription: String? {
        switch self {
        case .duplicateISBN(let isbn):
            return "이미 서재에 추가된 책입니다. (ISBN: \(isbn))"
        case .bookNotFound(let id):
            return "서재에서 해당 책을 찾을 수 없습니다. (ID: \(id))"
        }
    }
}
