//
//  TimerView.swift
//  Booktory
//
//  Created by 김지현 on 2/11/26.
//

import SwiftUI
import Combine

/// TimerView
/// 사용자가 책 읽을 때 나오는 타이머 화면
/// 일시정지, 재개 가능
/// 백그라운드 나가도 타이머는 동작해야 함
struct TimerView: View {
    @State private var startDate: Date? = nil
    @State private var pauseDate: Date? = nil      // 일시정지 시점
    @State private var elapsedBeforePause: TimeInterval = 0  // 일시정지 전까지의 누적 시간
    @State private var elapsed: TimeInterval = 0
    
    // 매초마다 UI 업데이트용 Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 12) {
                Image(systemName: "book")
                    .resizable()
                    .frame(height: 200)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.bottom, 12)
                
                Text("서울대 한국어(SNU Korean) 1B Student's Book")
                    .multilineTextAlignment(.center)
                    .font(.title2.bold())
                
                Text("최은규 진문이 오은영 송지현")
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            VStack(spacing: 20) {
                Text(formatTime(elapsed))
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                
                // 버튼 (상태에 따라 자동 전환)
                if startDate != nil {
                    // 🔴 빨간 원 + 일시정지 아이콘
                    Button(action: pause) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                } else {
                    // 🔵 파란 원 + 재생 아이콘
                    Button(action: resume) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.green)
                            .clipShape(Circle())
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

#Preview {
    TimerView()
}
