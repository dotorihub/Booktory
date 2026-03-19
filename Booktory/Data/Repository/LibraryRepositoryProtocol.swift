//
//  LibraryRepositoryProtocol.swift
//  Booktory
//

import Foundation

protocol LibraryRepositoryProtocol {

    // MARK: - LibraryBook 조회

    func fetchAll() throws -> [LibraryBook]
    func fetchBy(status: ReadingStatus) throws -> [LibraryBook]
    /// nil이면 서재에 없음
    func fetchBy(isbn: String) throws -> LibraryBook?

    // MARK: - LibraryBook 쓰기

    func add(_ book: LibraryBook) throws
    func updateStatus(id: UUID, to status: ReadingStatus) throws
    func delete(id: UUID) throws

    // MARK: - ReadingSession

    func addSession(_ session: ReadingSession, to bookId: UUID) throws
    func fetchSessions(for bookId: UUID) throws -> [ReadingSession]
    func fetchAllSessions() throws -> [ReadingSession]
}
