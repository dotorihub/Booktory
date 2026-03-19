//
//  DayCell.swift
//  Booktory
//
//  달력의 날짜 셀. 위클리/먼슬리 공용.
//  독서 depth에 따라 readingGreen의 opacity가 달라진다.
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let depth: Int          // 0~3
    let isSelected: Bool
    let isToday: Bool

    /// 위클리에서는 크게, 먼슬리에서는 작게
    var compact: Bool = false

    var body: some View {
        let day = Calendar.current.component(.day, from: date)

        Text("\(day)")
            .font(compact ? .caption : .subheadline)
            .fontWeight(isToday ? .bold : .regular)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 36 : 44)
            .background(depthColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.readingGreen : .clear, lineWidth: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.readingGreen.opacity(0.6) : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var depthColor: Color {
        switch depth {
        case 1: Color.readingGreen.opacity(0.3)
        case 2: Color.readingGreen.opacity(0.6)
        case 3: Color.readingGreen
        default: .clear
        }
    }
}

#Preview {
    HStack {
        DayCell(date: .now, depth: 0, isSelected: false, isToday: true)
        DayCell(date: .now, depth: 1, isSelected: false, isToday: false)
        DayCell(date: .now, depth: 2, isSelected: true, isToday: false)
        DayCell(date: .now, depth: 3, isSelected: false, isToday: false)
    }
    .padding()
}
