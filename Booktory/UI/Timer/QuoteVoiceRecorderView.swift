//
//  QuoteVoiceRecorderView.swift
//  Booktory
//
//  음성 기록 흐름 컨테이너 — 권한 확인 → 녹음 → 텍스트 편집 → 저장.
//  최종 저장 데이터는 텍스트(Quote.textContent)이며 오디오는 영구 저장되지 않는다.
//

import SwiftUI
import Speech

struct QuoteVoiceRecorderView: View {

    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = SpeechRecognitionService()

    private enum Stage {
        case awaitingPermission
        case recording
        case editing(String)
    }

    @State private var stage: Stage = .awaitingPermission
    @State private var showPermissionAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Group {
            switch stage {
            case .awaitingPermission:
                Color.black.ignoresSafeArea()

            case .recording:
                VoiceRecorderView(
                    service: speechService,
                    onCancel: { dismiss() },
                    onDone: { text in
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { dismiss(); return }
                        stage = .editing(trimmed)
                    }
                )

            case .editing(let initialText):
                ExtractedTextEditorView(
                    initialText: initialText,
                    onCancel: { dismiss() },
                    onSave: { text in
                        onSave(text)
                        dismiss()
                    }
                )
            }
        }
        .task {
            await requestPermissionsAndStart()
        }
        .alert("권한이 필요합니다", isPresented: $showPermissionAlert) {
            Button("설정 열기") { openAppSettings() }
            Button("취소", role: .cancel) { dismiss() }
        } message: {
            Text("설정 → 북토리에서 마이크 및 음성 인식 접근을 허용해주세요.")
        }
        .alert("음성 인식 오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) { dismiss() }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Permission & Start

    @MainActor
    private func requestPermissionsAndStart() async {
        let status = SpeechRecognitionService.currentStatus

        switch (status.speech, status.mic) {
        case (.authorized, .granted):
            startRecording()
        case (.denied, _), (.restricted, _), (_, .denied):
            showPermissionAlert = true
        default:
            let granted = await SpeechRecognitionService.requestPermissions()
            if granted {
                startRecording()
            } else {
                showPermissionAlert = true
            }
        }
    }

    private func startRecording() {
        do {
            try speechService.startRecording()
            stage = .recording
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        dismiss()
    }
}

#Preview {
    QuoteVoiceRecorderView { text in
        print("저장: \(text)")
    }
}
