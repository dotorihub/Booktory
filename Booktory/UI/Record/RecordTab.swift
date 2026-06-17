//
//  RecordTab.swift
//  Booktory
//
//  기록 탭 — 독서 중 남긴 문장 카드 목록.
//

import SwiftUI

// MARK: - Public Entry Point

struct RecordTabView: View {
    @Environment(\.libraryRepository) private var repository
    private let previewViewModel: RecordViewModel?

    init(viewModel: RecordViewModel? = nil) {
        self.previewViewModel = viewModel
    }

    var body: some View {
        RecordTabContentView(
            viewModel: previewViewModel ?? RecordViewModel(repository: repository)
        )
    }
}

// MARK: - Content View

private struct RecordTabContentView: View {
    @StateObject var viewModel: RecordViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.quotes.isEmpty {
                    ContentUnavailableView(
                        "기록 없음",
                        systemImage: "note.text",
                        description: Text("독서 중 문장을 기록하면 여기에 표시됩니다.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.quotes) { quote in
                                RecordQuoteCard(quote: quote)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.loadQuotes()
        }
    }
}

// MARK: - Previews

#Preview("기록 있음") {
    RecordTabView(
        viewModel: RecordViewModel(
            repository: PreviewLibraryRepository.populatedWithSessions()
        )
    )
    .environmentObject(AppCoordinator())
}

#Preview("빈 상태") {
    RecordTabView(
        viewModel: RecordViewModel(
            repository: PreviewLibraryRepository.empty()
        )
    )
    .environmentObject(AppCoordinator())
}
