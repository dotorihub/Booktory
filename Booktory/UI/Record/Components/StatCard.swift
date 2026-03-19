//
//  StatCard.swift
//  Booktory
//
//  개별 통계 카드 컴포넌트.
//

import SwiftUI

struct StatCard: View {
    let value: String
    let label: String
    var accentColor: Color = .readingGreen

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
    }
}

#Preview {
    HStack {
        StatCard(value: "3시간 20분", label: "이번 주")
        StatCard(value: "42시간", label: "전체 누적", accentColor: .booklyBlue)
        StatCard(value: "5권", label: "완독", accentColor: .booklyPurple)
    }
    .padding()
}
