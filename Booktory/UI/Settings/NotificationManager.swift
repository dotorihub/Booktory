//
//  NotificationManager.swift
//  Booktory
//
//  독서 리마인더 알림 스케줄 관리.
//  UNUserNotificationCenter를 통해 매일 반복 알림을 등록/취소한다.
//

import Foundation
import UserNotifications
import os

@MainActor
final class NotificationManager {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.booktory", category: "Notification")

    /// 리마인더 알림 식별자
    private let reminderIdentifier = "com.booktory.dailyReminder"

    private init() {}

    // MARK: - 권한 요청

    /// 알림 권한을 요청하고 결과를 반환한다.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("알림 권한 요청 결과: \(granted)")
            return granted
        } catch {
            logger.error("알림 권한 요청 실패: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - 권한 상태 확인

    /// 현재 알림 권한 상태를 반환한다.
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - 매일 반복 알림 등록

    /// 매일 지정 시간에 독서 리마인더 알림을 등록한다.
    /// 기존 알림을 취소한 뒤 새로 등록한다.
    func scheduleDaily(at time: Date) {
        cancelAll()

        let content = UNMutableNotificationContent()
        content.title = "독서 시간이에요 📖"
        content.body = "오늘도 책과 함께하는 시간을 가져보세요."
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { [weak self] error in
            if let error {
                self?.logger.error("알림 등록 실패: \(error.localizedDescription)")
            } else {
                self?.logger.info("매일 \(components.hour ?? 0):\(components.minute ?? 0) 알림 등록 완료")
            }
        }
    }

    // MARK: - 알림 취소

    /// 등록된 리마인더 알림을 모두 취소한다.
    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        logger.info("리마인더 알림 취소 완료")
    }
}
