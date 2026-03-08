//
//  LibraryTabViewModel.swift
//  Booktory
//

import Foundation
import Combine
import OSLog

private let logger = Logger(subsystem: "com.dotorihub.Booktory", category: "LibraryTabViewModel")

@MainActor
final class LibraryTabViewModel: ObservableObject {

    // MARK: - 상태

    @Published private(set) var books: [LibraryBook] = []
    @Published var selectedFilter: ReadingStatus? = nil   // nil = 전체
    @Published var layoutStyle: LibraryLayoutStyle = .grid
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: any LibraryRepositoryProtocol

    init(repository: any LibraryRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 공개 인터페이스

    func loadBooks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = selectedFilter == nil
                ? try repository.fetchAll()
                : try repository.fetchBy(status: selectedFilter!)
            books = sorted(fetched)
        } catch {
            logger.error("서재 로드 실패: \(error.localizedDescription)")
            errorMessage = "서재를 불러오지 못했습니다."
        }
    }

    func selectFilter(_ filter: ReadingStatus?) async {
        selectedFilter = filter
        await loadBooks()
    }

    // MARK: - 정렬

    private func sorted(_ items: [LibraryBook]) -> [LibraryBook] {
        switch selectedFilter {
        case .none:
            return items.sorted { $0.addedAt > $1.addedAt }

        case .reading:
            return items.sorted { a, b in
                let aTime = a.sessions.map(\.startTime).max()
                    ?? a.startedAt
                    ?? a.addedAt
                let bTime = b.sessions.map(\.startTime).max()
                    ?? b.startedAt
                    ?? b.addedAt
                return aTime > bTime
            }

        case .completed:
            return items.sorted {
                ($0.completedAt ?? $0.addedAt) > ($1.completedAt ?? $1.addedAt)
            }

        case .wantToRead:
            return items.sorted { $0.addedAt > $1.addedAt }
        }
    }
}

