//
//  SettingsViewModel.swift
//  Booktory
//
//  설정 화면 ViewModel. 리마인더 알림 ON/OFF 및 시간 설정을 관리한다.
//  UserDefaults(@AppStorage)로 설정값을 영속화하고
//  NotificationManager를 통해 알림을 등록/취소한다.
//

import Foundation
import UIKit
import Combine
import os

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published State

    /// 리마인더 알림 활성화 여부
    @Published var isReminderEnabled: Bool {
        didSet { handleReminderToggle() }
    }

    /// 리마인더 알림 시간
    @Published var reminderTime: Date {
        didSet { handleReminderTimeChange() }
    }

    /// 알림 권한이 거부되어 설정 앱 유도 Alert 표시 여부
    @Published var showPermissionAlert = false

    // MARK: - Private

    private let notificationManager = NotificationManager.shared
    private let logger = Logger(subsystem: "com.booktory", category: "Settings")

    /// UserDefaults 키
    private enum Keys {
        static let reminderEnabled = "settings.reminderEnabled"
        static let reminderHour = "settings.reminderHour"
        static let reminderMinute = "settings.reminderMinute"
    }

    // MARK: - Computed

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.isReminderEnabled = defaults.bool(forKey: Keys.reminderEnabled)

        // 저장된 시간 복원 (기본값: 21시 0분)
        let hour = defaults.object(forKey: Keys.reminderHour) as? Int ?? 21
        let minute = defaults.object(forKey: Keys.reminderMinute) as? Int ?? 0

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        self.reminderTime = Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Actions

    /// 리마인더 토글 변경 처리
    private func handleReminderToggle() {
        UserDefaults.standard.set(isReminderEnabled, forKey: Keys.reminderEnabled)

        if isReminderEnabled {
            Task { await enableReminder() }
        } else {
            notificationManager.cancelAll()
            logger.info("리마인더 비활성화")
        }
    }

    /// 리마인더 시간 변경 처리
    private func handleReminderTimeChange() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        UserDefaults.standard.set(components.hour, forKey: Keys.reminderHour)
        UserDefaults.standard.set(components.minute, forKey: Keys.reminderMinute)

        if isReminderEnabled {
            notificationManager.scheduleDaily(at: reminderTime)
            logger.info("리마인더 시간 변경: \(components.hour ?? 0):\(components.minute ?? 0)")
        }
    }

    /// 알림 권한 확인 후 리마인더 활성화
    private func enableReminder() async {
        let status = await notificationManager.authorizationStatus()

        switch status {
        case .notDetermined:
            let granted = await notificationManager.requestAuthorization()
            if granted {
                notificationManager.scheduleDaily(at: reminderTime)
            } else {
                isReminderEnabled = false
            }

        case .authorized, .provisional, .ephemeral:
            notificationManager.scheduleDaily(at: reminderTime)

        case .denied:
            // 권한 거부 상태 → 설정 앱 유도
            showPermissionAlert = true
            isReminderEnabled = false

        @unknown default:
            isReminderEnabled = false
        }
    }

    /// 설정 앱 열기
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
