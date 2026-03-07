//
//  DefaultLibraryRepository.swift
//  Booktory
//

import Foundation
import SwiftData
import OSLog

// MARK: - DefaultLibraryRepository

final class DefaultLibraryRepository: LibraryRepositoryProtocol {

    private let context: ModelContext
    private let logger = Logger(subsystem: "com.booktory", category: "LibraryRepository")

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
        let raw = status.rawValue
        let descriptor = FetchDescriptor<LibraryBook>(
            predicate: #Predicate { $0.statusRaw == raw },
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
        if let existing = try fetchBy(isbn: book.isbn) {
            logger.warning("중복 추가 시도 — isbn: \(book.isbn), 기존 상태: \(existing.statusRaw)")
            throw RepositoryError.duplicateISBN
        }
        context.insert(book)
        try context.save()
        logger.info("서재 추가 완료 — \(book.title)")
    }

    func updateStatus(id: UUID, to status: ReadingStatus) throws {
        guard let book = try fetchBook(by: id) else {
            logger.error("상태 변경 실패 — id를 찾을 수 없음: \(id)")
            throw RepositoryError.bookNotFound
        }
        book.status = status
        if status == .reading, book.startedAt == nil {
            book.startedAt = .now
        }
        if status == .completed {
            book.completedAt = .now
        }
        try context.save()
        logger.info("상태 변경 완료 — \(book.title): \(status.rawValue)")
    }

    func delete(id: UUID) throws {
        guard let book = try fetchBook(by: id) else {
            logger.error("삭제 실패 — id를 찾을 수 없음: \(id)")
            throw RepositoryError.bookNotFound
        }
        context.delete(book)
        try context.save()
        logger.info("서재 삭제 완료 — \(book.title)")
    }

    // MARK: - ReadingSession

    func addSession(_ session: ReadingSession, to bookId: UUID) throws {
        guard let book = try fetchBook(by: bookId) else {
            logger.error("세션 추가 실패 — bookId를 찾을 수 없음: \(bookId)")
            throw RepositoryError.bookNotFound
        }
        session.libraryBook = book
        context.insert(session)
        try context.save()
        logger.info("세션 저장 완료 — \(book.title), 독서 시간: \(session.duration)초")
    }

    func fetchSessions(for bookId: UUID) throws -> [ReadingSession] {
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.libraryBookId == bookId },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Private Helpers

    private func fetchBook(by id: UUID) throws -> LibraryBook? {
        let descriptor = FetchDescriptor<LibraryBook>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
}
