//
//  LiveActivityManager.swift
//  Booktory
//
//  Live Activity 생명주기 관리.
//  타이머 시작/일시정지/재개/종료 시점에 호출하여
//  Dynamic Island 및 잠금화면 타이머를 제어한다.
//

import Foundation
import ActivityKit
import os

@MainActor
final class LiveActivityManager {

    static let shared = LiveActivityManager()

    private var currentActivity: Activity<TimerActivityAttributes>?
    private let logger = Logger(subsystem: "com.booktory", category: "LiveActivity")

    private init() {}

    // MARK: - 시작

    /// 독서 타이머 시작 시 Live Activity를 시작한다.
    func start(bookTitle: String, startTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.info("Live Activity 권한이 비활성화되어 있음")
            return
        }

        // 기존 Activity가 있으면 먼저 종료
        if currentActivity != nil {
            stop()
        }

        let attributes = TimerActivityAttributes(bookTitle: bookTitle)
        let state = TimerActivityAttributes.ContentState(
            startTime: startTime,
            isPaused: false,
            elapsedBeforePause: 0
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            logger.info("Live Activity 시작: \(activity.id)")
        } catch {
            logger.error("Live Activity 시작 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 일시정지

    /// 타이머 일시정지 시 Live Activity를 일시정지 상태로 업데이트한다.
    func pause(elapsed: TimeInterval) {
        guard let activity = currentActivity else { return }

        let state = TimerActivityAttributes.ContentState(
            startTime: Date(), // 일시정지 상태에서는 의미 없음
            isPaused: true,
            elapsedBeforePause: elapsed
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
            logger.info("Live Activity 일시정지: elapsed=\(Int(elapsed))초")
        }
    }

    // MARK: - 재개

    /// 타이머 재개 시 Live Activity를 재개 상태로 업데이트한다.
    func resume(newStartTime: Date, elapsedBeforePause: TimeInterval) {
        guard let activity = currentActivity else { return }

        let state = TimerActivityAttributes.ContentState(
            startTime: newStartTime,
            isPaused: false,
            elapsedBeforePause: elapsedBeforePause
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
            logger.info("Live Activity 재개")
        }
    }

    // MARK: - 종료

    /// 타이머 종료 시 Live Activity를 종료한다.
    func stop() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            logger.info("Live Activity 종료: \(activity.id)")
        }
        currentActivity = nil
    }
}
