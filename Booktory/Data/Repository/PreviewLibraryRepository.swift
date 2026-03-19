//
//  PreviewLibraryRepository.swift
//  Booktory
//
//  Preview 및 테스트용 인메모리 구현체.
//  실제 저장소를 사용하지 않으므로 앱 실행 중에는 주입하지 않는다.
//

import Foundation

final class PreviewLibraryRepository: LibraryRepositoryProtocol {
    private var books: [LibraryBook] = []
    private var sessions: [ReadingSession] = []
    private var quotes: [Quote] = []

    // MARK: - LibraryBook 조회

    func fetchAll() throws -> [LibraryBook] {
        books.sorted { $0.addedAt > $1.addedAt }
    }

    func fetchBy(status: ReadingStatus) throws -> [LibraryBook] {
        books.filter { $0.status == status }.sorted { $0.addedAt > $1.addedAt }
    }

    func fetchBy(isbn: String) throws -> LibraryBook? {
        books.first { $0.isbn == isbn }
    }

    // MARK: - LibraryBook 쓰기

    func add(_ book: LibraryBook) throws {
        guard !books.contains(where: { $0.isbn == book.isbn }) else {
            throw LibraryRepositoryError.duplicateISBN(book.isbn)
        }
        // 순환 컬러 배정: 기존 책 수 기반으로 다음 colorIndex 부여
        book.colorIndex = books.count % BookColor.allCases.count
        books.append(book)
    }

    func updateStatus(id: UUID, to status: ReadingStatus) throws {
        guard let index = books.firstIndex(where: { $0.id == id }) else {
            throw LibraryRepositoryError.bookNotFound(id)
        }
        books[index].status = status
    }

    func delete(id: UUID) throws {
        guard books.contains(where: { $0.id == id }) else {
            throw LibraryRepositoryError.bookNotFound(id)
        }
        books.removeAll { $0.id == id }
        sessions.removeAll { $0.libraryBookId == id }
        quotes.removeAll { $0.libraryBookId == id }
    }

    // MARK: - ReadingSession

    func addSession(_ session: ReadingSession, to bookId: UUID) throws {
        guard let book = books.first(where: { $0.id == bookId }) else {
            throw LibraryRepositoryError.bookNotFound(bookId)
        }
        session.libraryBook = book
        sessions.append(session)
    }

    func fetchSessions(for bookId: UUID) throws -> [ReadingSession] {
        sessions.filter { $0.libraryBookId == bookId }.sorted { $0.startTime > $1.startTime }
    }

    func fetchAllSessions() throws -> [ReadingSession] {
        sessions.sorted { $0.startTime > $1.startTime }
    }

    // MARK: - Quote

    func addQuote(_ quote: Quote, to bookId: UUID) throws {
        guard let book = books.first(where: { $0.id == bookId }) else {
            throw LibraryRepositoryError.bookNotFound(bookId)
        }
        quote.libraryBook = book
        quotes.append(quote)
    }

    func fetchQuotes(for bookId: UUID) throws -> [Quote] {
        quotes.filter { $0.libraryBookId == bookId }.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchAllQuotes() throws -> [Quote] {
        quotes.sorted { $0.createdAt > $1.createdAt }
    }
}
