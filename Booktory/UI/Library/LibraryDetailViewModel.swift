//
//  LibraryDetailViewModel.swift
//  Booktory
//
//  서재 책 상세 화면의 상태 관리 및 비즈니스 로직.
//  세션 로드, 독서 통계 계산, 상태 변경, 삭제를 처리한다.
//

import Foundation
import Combine
import os

@MainActor
final class LibraryDetailViewModel: ObservableObject {

    // MARK: - 상태

    @Published private(set) var book: LibraryBook
    @Published private(set) var sessions: [ReadingSession] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    /// 삭제 확인 Alert 트리거
    @Published var showDeleteConfirm: Bool = false

    /// 삭제 완료 후 이전 화면으로 pop 트리거
    @Published var shouldDismiss: Bool = false

    /// 삭제 후 뷰 re-render 시 detached 객체 접근 방지
    @Published private(set) var isDeleted: Bool = false

    private let repository: any LibraryRepositoryProtocol
    private let logger = Logger(subsystem: "com.booktory", category: "LibraryDetail")

    init(book: LibraryBook, repository: any LibraryRepositoryProtocol) {
        self.book = book
        self.repository = repository
    }

    // MARK: - 공개 인터페이스

    /// 화면 진입 시 세션 목록 로드
    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try repository.fetchSessions(for: book.id)
        } catch {
            logger.error("세션 로드 실패: \(error.localizedDescription)")
            errorMessage = "독서 기록을 불러오지 못했습니다."
        }
    }

    /// 상태 변경: wantToRead → reading
    func startReading() async {
        do {
            try repository.updateStatus(id: book.id, to: .reading)
            book.status = .reading
            if book.startedAt == nil {
                book.startedAt = Date()
            }
        } catch {
            logger.error("상태 변경 실패: \(error.localizedDescription)")
            errorMessage = "상태를 변경하지 못했습니다."
        }
    }

    /// 상태 변경: reading → completed
    func markAsCompleted() async {
        do {
            try repository.updateStatus(id: book.id, to: .completed)
            book.status = .completed
            book.completedAt = Date()
        } catch {
            logger.error("완독 처리 실패: \(error.localizedDescription)")
            errorMessage = "완독 처리에 실패했습니다."
        }
    }

    /// 서재에서 삭제
    func deleteBook() async {
        do {
            // isDeleted를 먼저 설정하여 뷰가 삭제된 객체의 프로퍼티에 접근하지 않도록 한다
            isDeleted = true
            try repository.delete(id: book.id)
            shouldDismiss = true
        } catch {
            logger.error("삭제 실패: \(error.localizedDescription)")
            errorMessage = "삭제에 실패했습니다."
        }
    }

    // MARK: - 계산 프로퍼티

    /// 총 독서 시간 (초)
    var totalReadingSeconds: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    /// 총 독서 횟수
    var sessionCount: Int {
        sessions.count
    }

    /// 총 독서 시간 포맷 ("3시간 20분" / "45분" / "0분")
    var formattedTotalTime: String {
        let total = Int(totalReadingSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }
        return "\(minutes)분"
    }

    /// 서재 추가일 포맷
    var formattedAddedAt: String {
        book.addedAt.formatted(date: .abbreviated, time: .omitted)
    }

    /// 독서 시작일 포맷 (nil이면 "-")
    var formattedStartedAt: String {
        book.startedAt?.formatted(date: .abbreviated, time: .omitted) ?? "-"
    }

    /// 완독일 포맷 (nil이면 "-")
    var formattedCompletedAt: String {
        book.completedAt?.formatted(date: .abbreviated, time: .omitted) ?? "-"
    }
}
