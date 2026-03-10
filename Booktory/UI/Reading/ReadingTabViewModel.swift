//
//  ReadingTabViewModel.swift
//  Booktory
//
//  독서 탭의 상태 관리 및 비즈니스 로직.
//  reading 상태 책 목록 조회, 정렬, 타이머 자동 오픈을 처리한다.
//

import Foundation
import Combine
import os

@MainActor
final class ReadingTabViewModel: ObservableObject {

    // MARK: - 상태

    @Published private(set) var books: [LibraryBook] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    /// 현재 타이머에 열려 있는 책 (fullScreenCover 트리거)
    @Published var selectedBook: LibraryBook?

    /// 외부(View)에서 coordinator.pendingAutoOpenBookId를 전달받는 프로퍼티.
    /// loadBooks() 완료 후 해당 책을 찾아 selectedBook에 설정한다.
    var pendingAutoOpenId: UUID?

    private let repository: any LibraryRepositoryProtocol
    private let logger = Logger(subsystem: "com.booktory", category: "ReadingTab")

    init(repository: any LibraryRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 공개 인터페이스

    /// 탭 진입 / 갱신 시 호출
    func loadBooks() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try repository.fetchBy(status: .reading)
            books = sorted(fetched)

            // 로드 완료 후 pendingAutoOpen 처리
            if let pendingId = pendingAutoOpenId {
                selectedBook = books.first { $0.id == pendingId }
                pendingAutoOpenId = nil
            }
        } catch {
            logger.error("독서 탭 로드 실패: \(error.localizedDescription)")
            errorMessage = "목록을 불러오지 못했습니다."
        }
    }

    /// 특정 책의 누적 독서 시간 (초 단위)
    func totalReadingSeconds(for book: LibraryBook) -> TimeInterval {
        book.sessions.reduce(0) { $0 + $1.duration }
    }

    // MARK: - 정렬

    /// 세션이 있는 책: 가장 최근 세션 startTime 내림차순
    /// 세션이 없는 책: startedAt 내림차순
    /// 세션이 있는 책을 먼저 배치한다.
    private func sorted(_ books: [LibraryBook]) -> [LibraryBook] {
        let withSessions = books
            .filter { !$0.sessions.isEmpty }
            .sorted { lhs, rhs in
                let lhsLatest = lhs.sessions.map(\.startTime).max() ?? .distantPast
                let rhsLatest = rhs.sessions.map(\.startTime).max() ?? .distantPast
                return lhsLatest > rhsLatest
            }

        let withoutSessions = books
            .filter { $0.sessions.isEmpty }
            .sorted { ($0.startedAt ?? .distantPast) > ($1.startedAt ?? .distantPast) }

        return withSessions + withoutSessions
    }
}
