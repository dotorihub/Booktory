//
//  VoiceRecorderView.swift
//  Booktory
//
//  음성 녹음 UI. 마이크 버튼 + 실시간 텍스트 프리뷰 + 경과 시간.
//  [완료] 탭 → service.stopRecording() 결과를 onDone으로 전달.
//

import SwiftUI
import Combine

struct VoiceRecorderView: View {

    @ObservedObject var service: SpeechRecognitionService
    let onCancel: () -> Void
    let onDone: (String) -> Void

    @State private var elapsedSeconds: Int = 0
    @State private var pulseOpacity: Double = 0.3

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    transcriptPreview

                    Spacer()

                    Text(formattedTime)
                        .font(.system(.title2, design: .monospaced))
                        .foregroundStyle(.white)

                    micIndicator

                    Text(service.isRecording ? "녹음 중… [완료]를 눌러 저장하세요" : "")
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
            .onReceive(ticker) { _ in
                guard service.isRecording else { return }
                elapsedSeconds += 1
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulseOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Subviews

    private var transcriptPreview: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(service.transcript.isEmpty ? "말씀하세요…" : service.transcript)
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

    private var micIndicator: some View {
        ZStack {
            // pulse ring
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 110, height: 110)
                .opacity(service.isRecording ? pulseOpacity : 0)

            Circle()
                .fill(Color.red.opacity(0.12))
                .frame(width: 90, height: 90)
                .opacity(service.isRecording ? pulseOpacity : 0)

            // 마이크 버튼 (탭 불필요 — 진입 즉시 녹음 중)
            Circle()
                .fill(service.isRecording ? Color.red : Color.white.opacity(0.15))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                )
        }
    }

    // MARK: - Helpers

    private var formattedTime: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }
}

#Preview {
    VoiceRecorderView(
        service: SpeechRecognitionService(),
        onCancel: { print("cancel") },
        onDone: { print("done: \($0)") }
    )
}
