//
//  BooktoryLiveActivityLiveActivity.swift
//  BooktoryLiveActivity
//
//  독서 타이머 Live Activity의 Dynamic Island 및 잠금화면 UI 정의.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BooktoryLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // MARK: - 잠금화면 Live Activity
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded (길게 눌렀을 때)
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "book.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerText(context: context)
                        .font(.title2.monospacedDigit().bold())
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.bookTitle)
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isPaused {
                        Label("일시정지", systemImage: "pause.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("독서 중", systemImage: "book.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            } compactLeading: {
                // MARK: - Compact Leading (좌측 알약)
                Image(systemName: "book.fill")
                    .foregroundStyle(.green)
            } compactTrailing: {
                // MARK: - Compact Trailing (우측 알약)
                timerText(context: context)
                    .font(.caption.monospacedDigit())
            } minimal: {
                // MARK: - Minimal (다른 Activity와 공존 시)
                Image(systemName: "book.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - 잠금화면 뷰

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<TimerActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.bookTitle)
                    .font(.headline)
                    .lineLimit(1)

                if context.state.isPaused {
                    Text("일시정지")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("독서 중")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            // 보이지 않는 참조 텍스트로 너비를 확보하고, 실제 타이머를 overlay로 표시
            Text("00:00:00")
                .font(.title3.monospacedDigit().bold())
                .hidden()
                .overlay(alignment: .trailing) {
                    timerText(context: context)
                        .font(.title3.monospacedDigit().bold())
                        .multilineTextAlignment(.trailing)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .activityBackgroundTint(.black.opacity(0.7))
        .activitySystemActionForegroundColor(.white)
    }

    // MARK: - 타이머 텍스트

    /// 일시정지 상태에서는 고정 시간, 진행 중에는 timerInterval로 실시간 표시
    @ViewBuilder
    private func timerText(context: ActivityViewContext<TimerActivityAttributes>) -> some View {
        if context.state.isPaused {
            // 일시정지: 누적 시간을 고정 표시
            Text(formatElapsed(context.state.elapsedBeforePause))
        } else {
            // 진행 중: startTime 기준 실시간 타이머
            // elapsedBeforePause 오프셋을 반영하기 위해 시작 시간을 역산
            let adjustedStart = context.state.startTime.addingTimeInterval(-context.state.elapsedBeforePause)
            Text(timerInterval: adjustedStart...Date.distantFuture, countsDown: false)
                .multilineTextAlignment(.trailing)
        }
    }

    /// TimeInterval → "HH:MM:SS" 포맷
    private func formatElapsed(_ elapsed: TimeInterval) -> String {
        let total = Int(elapsed)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Preview

extension TimerActivityAttributes {
    fileprivate static var preview: TimerActivityAttributes {
        TimerActivityAttributes(bookTitle: "데미안")
    }
}

extension TimerActivityAttributes.ContentState {
    fileprivate static var running: TimerActivityAttributes.ContentState {
        TimerActivityAttributes.ContentState(
            startTime: Date(),
            isPaused: false,
            elapsedBeforePause: 0
        )
    }

    fileprivate static var paused: TimerActivityAttributes.ContentState {
        TimerActivityAttributes.ContentState(
            startTime: Date(),
            isPaused: true,
            elapsedBeforePause: 1234
        )
    }
}

#Preview("Notification", as: .content, using: TimerActivityAttributes.preview) {
    BooktoryLiveActivityLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState.running
    TimerActivityAttributes.ContentState.paused
}
