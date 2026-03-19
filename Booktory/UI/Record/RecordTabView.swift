//
//  RecordTabView.swift
//  Booktory
//
//  기록 탭 — 독서 통계 + 위클리/먼슬리 달력 히트맵.
//

import SwiftUI

// MARK: - Public Entry Point

/// 환경에서 repository를 읽어 ViewModel을 생성하는 진입 뷰.
/// Preview에서는 viewModel을 직접 주입해 실제 DB 없이 동작한다.
struct RecordTabView: View {
    @Environment(\.libraryRepository) private var repository
    private let previewViewModel: RecordTabViewModel?

    init(viewModel: RecordTabViewModel? = nil) {
        self.previewViewModel = viewModel
    }

    var body: some View {
        RecordTabContentView(
            viewModel: previewViewModel ?? RecordTabViewModel(repository: repository)
        )
    }
}

// MARK: - Content View

private struct RecordTabContentView: View {
    @StateObject var viewModel: RecordTabViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 통계 카드
                    StatsSection(
                        weeklyDuration: viewModel.weeklyDuration,
                        totalDuration: viewModel.totalDuration,
                        completedCount: viewModel.completedCount
                    )

                    // 달력 모드 토글
                    CalendarToggle(mode: $viewModel.calendarMode)

                    // 달력
                    switch viewModel.calendarMode {
                    case .weekly:
                        WeeklyCalendarView(viewModel: viewModel)
                    case .monthly:
                        MonthlyCalendarView(viewModel: viewModel)
                    }

                    // 선택 날짜 책 표지 카드 목록
                    DayBookList(
                        date: viewModel.selectedDate,
                        summaries: viewModel.bookSummaries(for: viewModel.selectedDate)
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Previews

#Preview("세션 있음") {
    RecordTabView(
        viewModel: RecordTabViewModel(
            repository: PreviewLibraryRepository.populatedWithSessions()
        )
    )
    .environmentObject(AppCoordinator())
}

#Preview("빈 상태") {
    RecordTabView(
        viewModel: RecordTabViewModel(
            repository: PreviewLibraryRepository.empty()
        )
    )
    .environmentObject(AppCoordinator())
}
