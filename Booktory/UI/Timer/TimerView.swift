//
//  TimerView.swift
//  Booktory
//
//  Created by 김지현 on 2/11/26.
//

import SwiftUI
import Combine
import SwiftData

/// TimerView
/// 사용자가 책 읽을 때 나오는 타이머 화면
/// 일시정지, 재개 가능
/// 백그라운드 나가도 타이머는 동작해야 함
struct TimerView: View {
    let book: LibraryBook

    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date? = nil
    @State private var pauseDate: Date? = nil      // 일시정지 시점
    @State private var elapsedBeforePause: TimeInterval = 0  // 일시정지 전까지의 누적 시간
    @State private var elapsed: TimeInterval = 0

    // 매초마다 UI 업데이트용 Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 12) {
                AsyncImage(url: URL(string: book.coverURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        bookPlaceholder
                    case .empty:
                        ProgressView()
                            .frame(width: 120, height: 180)
                    @unknown default:
                        bookPlaceholder
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.bottom, 12)

                Text(book.title)
                    .multilineTextAlignment(.center)
                    .font(.title2.bold())
                    .lineLimit(2)

                Text(book.author)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            VStack(spacing: 20) {
                Text(formatTime(elapsed))
                    .font(.system(size: 44, weight: .bold, design: .monospaced))

                HStack(spacing: 32) {
                    // 나가기 버튼
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("나가기")

                    // 재생/일시정지 버튼
                    if startDate != nil {
                        Button(action: pause) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("일시정지")
                    } else {
                        Button(action: resume) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("재개")
                    }
                }
            }
        }
        .padding(.vertical, 80)
        .onAppear {
            start()
        }
        .onReceive(timer) { _ in
            updateElapsed()
        }
    }

    // MARK: - Placeholder

    private var bookPlaceholder: some View {
        Image(systemName: "book.closed")
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
            .frame(width: 120, height: 180)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Timer Logic

    func start() {
        startDate = Date()
        pauseDate = nil
        elapsedBeforePause = 0
    }

    func pause() {
        guard let start = startDate else { return }
        pauseDate = Date()
        elapsedBeforePause += pauseDate!.timeIntervalSince(start)
        startDate = nil
    }

    func resume() {
        startDate = Date()
        pauseDate = nil
    }

    func updateElapsed() {
        if let start = startDate {
            elapsed = elapsedBeforePause + Date().timeIntervalSince(start)
        } else {
            elapsed = elapsedBeforePause
        }
    }

    // MARK: - Format
    // HH:mm:ss 형식으로 변환
    func formatTime(_ interval: TimeInterval) -> String {
        let sec = Int(interval) % 60
        let min = (Int(interval) / 60) % 60
        let hour = Int(interval) / 3600

        return String(format: "%02d:%02d:%02d", hour, min, sec)
    }
}
