//
//  SettingsPlaceholderView.swift
//  Booktory
//
//  설정 화면 플레이스홀더. Phase 3에서 실제 구현 예정.
//

import SwiftUI

struct SettingsPlaceholderView: View {

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("버전")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsPlaceholderView()
    }
}
