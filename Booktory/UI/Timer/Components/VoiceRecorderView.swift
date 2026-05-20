//
//  VoiceRecorderView.swift
//  Booktory
//
//  음성 녹음 UI. 재생/일시정지 버튼 + 실시간 텍스트 프리뷰.
//  [완료] 탭 → service.stopRecording() 결과를 onDone으로 전달.
//

import SwiftUI

struct VoiceRecorderView: View {

    @ObservedObject var service: SpeechRecognitionService
    let onCancel: () -> Void
    let onDone: (String) -> Void

    @State private var pulseOpacity: Double = 0.3
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 40) {
                    transcriptPreview

                    Spacer()

                    playPauseButton

                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationTitle("음성 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        service.stopRecording()
                        onCancel()
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        let text = service.stopRecording()
                        onDone(text)
                    }
                    .foregroundStyle(.yellow)
                    .fontWeight(.semibold)
                    .disabled(service.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulseOpacity = 1.0
                }
            }
            .alert("오류", isPresented: $showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Subviews

    private var transcriptPreview: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(service.transcript.isEmpty ? "재생 버튼을 눌러 녹음을 시작하세요" : service.transcript)
                    .font(.body)
                    .foregroundStyle(service.transcript.isEmpty ? Color.white.opacity(0.35) : .white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .id("bottom")
                    .onChange(of: service.transcript) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
            }
            .frame(maxHeight: 220)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var playPauseButton: some View {
        ZStack {
            // pulse ring — 녹음 중일 때만 표시
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 110, height: 110)
                .opacity(service.state == .recording ? pulseOpacity : 0)

            Circle()
                .fill(Color.red.opacity(0.12))
                .frame(width: 90, height: 90)
                .opacity(service.state == .recording ? pulseOpacity : 0)

            Button(action: toggleRecording) {
                Circle()
                    .fill(service.state == .recording ? Color.red : Color.white.opacity(0.2))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: service.state == .recording ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    )
            }
        }
    }

    // MARK: - Helpers

    private var statusLabel: String {
        switch service.state {
        case .idle:      return "재생 버튼을 눌러 녹음 시작"
        case .recording: return "녹음 중…  완료를 눌러 저장"
        case .paused:    return "일시정지됨"
        }
    }

    private func toggleRecording() {
        do {
            switch service.state {
            case .idle:      try service.startRecording()
            case .recording: service.pauseRecording()
            case .paused:    try service.resumeRecording()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    VoiceRecorderView(
        service: SpeechRecognitionService(),
        onCancel: { print("cancel") },
        onDone: { print("done: \($0)") }
    )
}
