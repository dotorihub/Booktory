//
//  Color+.swift
//  Booktory
//
//  Created by 김지현 on 2/9/26.
//

import SwiftUI

// MARK: - Bookly Color System
extension Color {

    // MARK: Brand Colors
    static let booklyBlue = Color(hex: "#007AFF")
    static let booklyPurple = Color(hex: "#5856D6")

    // Brand Gradient
    static let booklyGradient = LinearGradient(
        colors: [Color.booklyBlue, Color.booklyPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Backgrounds (Light / Dark)
    static let lightBase = Color(hex: "#F2F2F7")
    static let darkBase = Color(hex: "#000000")

    static let lightSurface = Color(hex: "#FFFFFF")
    static let darkSurface = Color(hex: "#1C1C1E")

    static let dividerLight = Color(hex: "#E5E5EA")
    static let dividerDark = Color(hex: "#2C2C2E")

    // MARK: Text Colors
    static let textPrimaryLight = Color(hex: "#000000")
    static let textPrimaryDark = Color(hex: "#FFFFFF")

    static let textSecondary = Color(hex: "#8E8E93")
    static let textTertiary = Color(hex: "#AEAEB2")

    // MARK: Semantic Colors
    static let success = Color(hex: "#34C759")
    static let destructive = Color(hex: "#FF3B30")
    static let warning = Color(hex: "#FF9500")
    static let info = Color(hex: "#5AC8FA")

    // MARK: Book App Accent Colors
    static let paperGray = Color(hex: "#F9F9FB")
    static let bookmarkRed = Color(hex: "#FF6B6B")
    static let readingGreen = Color(hex: "#6BCF9D")
    static let highlightYellow = Color(hex: "#FFD60A")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
