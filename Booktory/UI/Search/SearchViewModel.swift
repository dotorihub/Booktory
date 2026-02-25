//
//  SearchViewModel.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {

    enum State {
        case idle
        case loading
        case loaded([Book])
        case failed(String)
    }

    @Published var state: State = .idle
    @Published var query: String = ""

    // Pagination
    @Published private(set) var books: [Book] = []
    private var isLoading: Bool = false
    private var currentStart: Int = 1
    private let display: Int = 20
    private var hasMore: Bool = true

    private let service: BookSearchService
    private var searchTask: Task<Void, Never>?

    init(service: BookSearchService = DefaultBookSearchService()) {
        self.service = service
    }

    // 첫 페이지 검색 (query 기준)
    func search() async {
        // 중요: 여기서 searchTask?.cancel()를 호출하면
        // 현재 실행 중인 자신(최신 Task)도 취소될 수 있으므로 제거합니다.

        let currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentQuery.isEmpty else {
            reset()
            return
        }

        // 초기화
        isLoading = true
        state = .loading
        books = []
        currentStart = 1
        hasMore = true

        do {
            let result = try await service.searchBooks(query: currentQuery, start: currentStart, display: display)
            books = result
            state = .loaded(books)
            // 받은 수가 페이지 크기보다 작으면 더 없음
            hasMore = result.count == display
            if hasMore {
                currentStart += display
            }
        } catch let apiError as APIError {
            state = .failed(apiError.errorDescription ?? "Unknown error")
            hasMore = false
        } catch is CancellationError {
            // 최신 요청이 아닌 이전 요청이 취소된 경우가 대부분이므로 실패 UI로 바꾸지 않음
            isLoading = false
        } catch {
            state = .failed(error.localizedDescription)
            hasMore = false
        }
        isLoading = false
    }

    // 다음 페이지 로드
    func loadNextPageIfNeeded(currentItem item: Book?) async {
        guard hasMore, !isLoading else { return }
        // 리스트의 마지막 아이템 근처에서만 트리거
        guard let item = item, let last = books.last, item.id == last.id else { return }

        let currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !currentQuery.isEmpty else { return }

        isLoading = true
        do {
            let result = try await service.searchBooks(query: currentQuery, start: currentStart, display: display)
            // Append
            books.append(contentsOf: result)
            state = .loaded(books)
            // 더 받을 수 있는지 판단
            hasMore = result.count == display
            if hasMore {
                currentStart += display
            }
        } catch is CancellationError {
            // 페이지네이션 취소는 조용히 무시
        } catch {
            state = .failed(error.localizedDescription)
            hasMore = false
        }
        isLoading = false
    }

    func searchWithDebounce(delay: Duration = .milliseconds(350)) {
        // 이전 디바운스 태스크 취소
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard let self else { return }
            await self.search()
        }
    }

    func submitSearch() {
        // 수동 제출 시에도 최신-우선 정책으로 이전 태스크 취소
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            await self.search()
        }
    }

    func clear() {
        query = ""
        reset()
        searchTask?.cancel()
        searchTask = nil
    }

    private func reset() {
        books = []
        state = .idle
        isLoading = false
        hasMore = true
        currentStart = 1
    }
}
