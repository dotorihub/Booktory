//
//  DayBookList.swift
//  Booktory
//
//  선택된 날짜의 책 표지 카드 목록.
//  기존 DaySessionList를 대체하여 달력 하단에 표시한다.
//

import SwiftUI

struct DayBookList: View {
    let date: Date
    let summaries: [DayBookSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                .font(.subheadline.bold())
                .padding(.horizontal)

            if summaries.isEmpty {
                emptyView
            } else {
                ForEach(summaries) { summary in
                    DayBookCard(summary: summary)
                }
            }
        }
    }

    private var emptyView: some View {
        Text("이 날은 독서를 하지 않았어요")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }
}

#Preview {
    DayBookList(date: .now, summaries: [
        DayBookSummary(id: UUID(), title: "클린 코드", coverURL: "", bookColor: .red, totalDuration: 5400),
        DayBookSummary(id: UUID(), title: "함께 자라기", coverURL: "", bookColor: .orange, totalDuration: 2700),
    ])
}

#Preview("빈 상태") {
    DayBookList(date: .now, summaries: [])
}
