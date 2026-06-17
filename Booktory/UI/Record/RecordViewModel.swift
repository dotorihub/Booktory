//
//  RecordViewModel.swift
//  Booktory
//
//  기록 탭의 상태 관리. Quote 목록 로드 및 삭제 처리.
//

import Foundation
import Combine
import os

@MainActor
final class RecordViewModel: ObservableObject {

    @Published private(set) var quotes: [Quote] = []

    private let repository: any LibraryRepositoryProtocol
    private let logger = Logger(subsystem: "com.booktory", category: "RecordTab")

    init(repository: any LibraryRepositoryProtocol) {
        self.repository = repository
    }

    func loadQuotes() async {
        do {
            quotes = try repository.fetchAllQuotes()
                .filter { $0.textContent != nil }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            logger.error("기록 로드 실패: \(error.localizedDescription)")
        }
    }

    func deleteQuote(_ quote: Quote) async {
        do {
            try repository.deleteQuote(id: quote.id)
            quotes.removeAll { $0.id == quote.id }
        } catch {
            logger.error("기록 삭제 실패: \(error.localizedDescription)")
        }
    }
}
