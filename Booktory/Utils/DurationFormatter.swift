//
//  DurationFormatter.swift
//  Booktory
//

import Foundation

enum DurationFormatter {

    /// `TimeInterval`(초)을 한국어 시간 문자열로 변환한다.
    /// - 1시간 이상: "X시간 Y분"
    /// - 1시간 미만: "Y분"
    /// - 1분 미만: "1분 미만"
    static func format(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours   = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if minutes > 0 {
            return "\(minutes)분"
        } else {
            return "1분 미만"
        }
    }

    /// 세션 배열의 총 독서 시간을 포맷한다.
    static func totalFormatted(sessions: [ReadingSession]) -> String {
        let total = sessions.reduce(0.0) { $0 + $1.duration }
        return format(total)
    }
}
