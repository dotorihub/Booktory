//
//  LibraryRepositoryProtocol.swift
//  Booktory
//

import Foundation

// MARK: - RepositoryError

enum RepositoryError: LocalizedError {
    case bookNotFound
    case duplicateISBN

    var errorDescription: String? {
        switch self {
        case .bookNotFound:  return "서재에서 책을 찾을 수 없습니다."
        case .duplicateISBN: return "이미 서재에 있는 책입니다."
        }
    }
}

// MARK: - LibraryRepositoryProtocol

protocol LibraryRepositoryProtocol {

    // MARK: LibraryBook 조회

    /// 서재의 전체 책 목록 (추가 날짜 내림차순)
    func fetchAll() throws -> [LibraryBook]

    /// 특정 상태의 책 목록
    func fetchBy(status: ReadingStatus) throws -> [LibraryBook]

    /// ISBN으로 단건 조회. nil이면 서재에 없음.
    func fetchBy(isbn: String) throws -> LibraryBook?

    // MARK: LibraryBook 쓰기

    /// 서재에 책 추가. 동일 ISBN이 이미 있으면 RepositoryError.duplicateISBN throw.
    func add(_ book: LibraryBook) throws

    /// 책 상태 변경 (wantToRead → reading → completed)
    func updateStatus(id: UUID, to status: ReadingStatus) throws

    /// 서재에서 책 삭제. 연결된 ReadingSession도 cascade 삭제.
    func delete(id: UUID) throws

    // MARK: ReadingSession

    /// 독서 세션 추가. 최소 60초 미만이면 저장 생략 (호출자가 판단 후 호출 권장).
    func addSession(_ session: ReadingSession, to bookId: UUID) throws

    /// 특정 책의 세션 목록 (시작 시간 내림차순)
    func fetchSessions(for bookId: UUID) throws -> [ReadingSession]
}
