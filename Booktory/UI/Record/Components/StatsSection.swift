//
//  StatsSection.swift
//  Booktory
//
//  통계 카드 3개를 HStack으로 배치하는 섹션.
//

import SwiftUI

struct StatsSection: View {
    let weeklyDuration: TimeInterval
    let totalDuration: TimeInterval
    let completedCount: Int

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                value: DurationFormatter.format(weeklyDuration),
                label: "이번 주"
            )
            StatCard(
                value: DurationFormatter.format(totalDuration),
                label: "전체 누적",
                accentColor: .booklyBlue
            )
            StatCard(
                value: "\(completedCount)권",
                label: "완독",
                accentColor: .booklyPurple
            )
        }
        .padding(.horizontal)
    }
}

#Preview {
    StatsSection(weeklyDuration: 12000, totalDuration: 151200, completedCount: 5)
}
