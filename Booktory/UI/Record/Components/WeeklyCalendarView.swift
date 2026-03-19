//
//  WeeklyCalendarView.swift
//  Booktory
//
//  이번 주(월~일) 7일 히트맵 달력.
//

import SwiftUI

struct WeeklyCalendarView: View {
    @ObservedObject var viewModel: RecordTabViewModel

    private let weekdayLabels = ["월", "화", "수", "목", "금", "토", "일"]
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 셀
            HStack(spacing: 4) {
                ForEach(viewModel.currentWeekDates, id: \.self) { date in
                    DayCell(
                        date: date,
                        depth: viewModel.readingDepth(for: date),
                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: calendar.isDateInToday(date)
                    )
                    .onTapGesture {
                        viewModel.selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    WeeklyCalendarView(
        viewModel: RecordTabViewModel(repository: PreviewLibraryRepository.populatedWithSessions())
    )
}
