//
//  BookColor.swift
//  Booktory
//
//  책에 부여되는 고유 컬러. 서재에 추가 순서대로 순환 배정된다.
//  달력 도트, 책 표지 카드의 컬러 뱃지에 사용.
//

import SwiftUI

enum BookColor: Int, CaseIterable, Sendable {
    case red = 0
    case orange = 1
    case yellow = 2
    case green = 3
    case blue = 4

    var color: Color {
        switch self {
        case .red: Color(hex: "#FF6B6B")
        case .orange: Color(hex: "#FF9F43")
        case .yellow: Color(hex: "#FECA57")
        case .green: Color(hex: "#48DBAB")
        case .blue: Color(hex: "#54A0FF")
        }
    }

    var label: String {
        switch self {
        case .red: "빨강"
        case .orange: "주황"
        case .yellow: "노랑"
        case .green: "초록"
        case .blue: "파랑"
        }
    }

    /// colorIndex로부터 BookColor 생성 (순환)
    static func from(index: Int) -> BookColor {
        let safeIndex = index % allCases.count
        return allCases[safeIndex]
    }
}
