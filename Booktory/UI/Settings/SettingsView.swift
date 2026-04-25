//
//  SettingsView.swift
//  Booktory
//
//  설정 화면. 독서 리마인더 알림 설정 및 앱 정보를 표시한다.
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            reminderSection
            appInfoSection
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .alert("알림 권한 필요", isPresented: $viewModel.showPermissionAlert) {
            Button("설정으로 이동") { viewModel.openSettings() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("독서 리마인더를 사용하려면 알림 권한이 필요합니다. 설정에서 알림을 허용해 주세요.")
        }
    }

    // MARK: - 리마인더 섹션

    private var reminderSection: some View {
        Section {
            Toggle("독서 리마인더", isOn: $viewModel.isReminderEnabled)

            if viewModel.isReminderEnabled {
                DatePicker(
                    "알림 시간",
                    selection: $viewModel.reminderTime,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("알림")
        } footer: {
            Text("매일 설정한 시간에 독서 리마인더 알림을 받을 수 있습니다.")
        }
    }

    // MARK: - 앱 정보 섹션

    private var appInfoSection: some View {
        Section("앱 정보") {
            HStack {
                Text("버전")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
