//
//  DayCell.swift
//  Booktory
//
//  달력의 날짜 셀. 위클리/먼슬리 공용.
//  독서 depth에 따라 해당 날 읽은 책의 컬러 opacity가 달라진다.
//  여러 책을 읽은 날은 첫 번째 책(colorIndex 오름차순) 컬러를 사용.
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let depth: Int          // 0~3
    let isSelected: Bool
    let isToday: Bool

    /// 위클리에서는 크게, 먼슬리에서는 작게
    var compact: Bool = false

    /// 해당 날 읽은 책들의 컬러 (중복 제거, colorIndex 오름차순)
    var dots: [BookColor] = []

    var body: some View {
        let day = Calendar.current.component(.day, from: date)

        VStack(spacing: compact ? 2 : 4) {
            Text("\(day)")
                .font(compact ? .caption : .subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 28 : 36)
                .background(depthColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? accentColor : .clear, lineWidth: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? accentColor.opacity(0.6) : .clear, lineWidth: 2)
                )

            // 컬러 도트 (최대 5개)
            if !dots.isEmpty {
                HStack(spacing: compact ? 1 : 2) {
                    ForEach(dots.prefix(5), id: \.rawValue) { bookColor in
                        Circle()
                            .fill(bookColor.color)
                            .frame(width: compact ? 4 : 6, height: compact ? 4 : 6)
                    }
                }
                .frame(height: compact ? 4 : 6)
            } else {
                // 도트가 없을 때도 공간 확보 (레이아웃 안정성)
                Spacer()
                    .frame(height: compact ? 4 : 6)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    /// 오늘/선택 테두리에 사용할 강조색
    private var accentColor: Color {
        dots.first?.color ?? .readingGreen
    }

    /// 책 컬러 기반 depth 배경색. 도트가 있으면 첫 번째 책 컬러 사용, 없으면 readingGreen 폴백.
    private var depthColor: Color {
        let baseColor = dots.first?.color ?? .readingGreen
        switch depth {
        case 1: return baseColor.opacity(0.3)
        case 2: return baseColor.opacity(0.6)
        case 3: return baseColor
        default: return Color.clear
        }
    }
}

#Preview {
    HStack {
        DayCell(date: .now, depth: 0, isSelected: false, isToday: true)
        DayCell(date: .now, depth: 1, isSelected: false, isToday: false, dots: [.red])
        DayCell(date: .now, depth: 2, isSelected: true, isToday: false, dots: [.red, .orange])
        DayCell(date: .now, depth: 3, isSelected: false, isToday: false, dots: [.red, .blue, .green])
    }
    .padding()
}
