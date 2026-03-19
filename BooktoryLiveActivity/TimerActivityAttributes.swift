//
//  TimerActivityAttributes.swift
//  Booktory
//
//  Live Activity에서 사용하는 Attributes 정의.
//  메인 앱과 Widget Extension 양쪽 타겟에 포함되어야 한다.
//

import Foundation
import ActivityKit

struct TimerActivityAttributes: ActivityAttributes {
    /// 고정 데이터: Activity 시작 시 설정, 이후 변경 불가
    var bookTitle: String

    /// 동적 데이터: Activity 업데이트마다 변경 가능
    struct ContentState: Codable, Hashable {
        var startTime: Date
        var isPaused: Bool
        var elapsedBeforePause: TimeInterval
    }
}
