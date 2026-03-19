//
//  MonthlyCalendarView.swift
//  Booktory
//
//  먼슬리 달력. 월 이동 + 7열 그리드 히트맵.
//

import SwiftUI

struct MonthlyCalendarView: View {
    @ObservedObject var viewModel: RecordTabViewModel

    private let weekdayLabels = ["월", "화", "수", "목", "금", "토", "일"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            // 월 헤더: < 2026년 3월 >
            monthHeader

            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(viewModel.monthlyGridDates.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            depth: viewModel.readingDepth(for: date),
                            isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                            isToday: calendar.isDateInToday(date),
                            compact: true,
                            dots: viewModel.bookColors(for: date)
                        )
                        .onTapGesture {
                            viewModel.selectedDate = date
                        }
                    } else {
                        // 1일 이전의 빈 셀
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.moveToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel("이전 달")

            Spacer()

            Text(viewModel.displayedMonthTitle)
                .font(.headline)

            Spacer()

            Button {
                viewModel.moveToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
                    .foregroundStyle(viewModel.canMoveToNextMonth ? .primary : .tertiary)
            }
            .disabled(!viewModel.canMoveToNextMonth)
            .accessibilityLabel("다음 달")
        }
    }
}

#Preview {
    MonthlyCalendarView(
        viewModel: RecordTabViewModel(repository: PreviewLibraryRepository.populatedWithSessions())
    )
}
