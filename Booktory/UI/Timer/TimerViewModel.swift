//
//  TimerViewModel.swift
//  Booktory
//
//  타이머 상태 관리 및 세션 저장 로직.
//  기존 TimerView의 @State 로직을 ViewModel로 분리하고,
//  나가기 시 ReadingSession을 Repository에 저장한다.
//

import Foundation
import Combine
import os

@MainActor
final class TimerViewModel: ObservableObject {

    // MARK: - 타이머 상태

    enum TimerState {
        case idle     // 초기 상태 (진입 직후)
        case running  // 타이머 진행 중
        case paused   // 일시정지
    }

    @Published private(set) var timerState: TimerState = .idle
    @Published private(set) var elapsed: TimeInterval = 0

    /// 나가기 확인 Alert 트리거
    @Published var showExitConfirm: Bool = false

    let book: LibraryBook

    // MARK: - 내부 상태

    /// 세션 전체의 시작 시각 (최초 start 시 기록)
    private var sessionStartTime: Date?

    /// 현재 진행 구간의 시작 시각 (resume마다 갱신)
    private var currentRunStartDate: Date?

    /// 일시정지 전까지의 누적 시간
    private var elapsedBeforePause: TimeInterval = 0

    private let repository: any LibraryRepositoryProtocol
    private let logger = Logger(subsystem: "com.booktory", category: "Timer")

    /// 최소 세션 저장 기준 (초)
    private let minimumSessionDuration: TimeInterval = 60

    init(book: LibraryBook, repository: any LibraryRepositoryProtocol) {
        self.book = book
        self.repository = repository
    }

    // MARK: - 타이머 제어

    /// 타이머 시작 (onAppear에서 자동 호출)
    func start() {
        sessionStartTime = Date()
        currentRunStartDate = Date()
        timerState = .running
    }

    /// 일시정지
    func pause() {
        guard timerState == .running, let runStart = currentRunStartDate else { return }
        elapsedBeforePause += Date().timeIntervalSince(runStart)
        currentRunStartDate = nil
        timerState = .paused
    }

    /// 재개
    func resume() {
        currentRunStartDate = Date()
        timerState = .running
    }

    /// Timer.publish 매 틱마다 호출
    func tick() {
        guard timerState == .running, let runStart = currentRunStartDate else { return }
        elapsed = elapsedBeforePause + Date().timeIntervalSince(runStart)
    }

    // MARK: - 나가기 플로우

    /// 나가기 버튼 탭 시 호출.
    /// - Returns: `true`이면 바로 dismiss 가능, `false`이면 확인 Alert 대기
    func requestExit() -> Bool {
        if timerState == .idle {
            return true
        }
        // running 상태면 먼저 일시정지
        if timerState == .running {
            pause()
        }
        showExitConfirm = true
        return false
    }

    /// 확인 Alert에서 [종료하기] 선택 시 호출
    func confirmExit() {
        saveSessionIfNeeded()
    }

    /// 확인 Alert에서 [계속 읽기] 선택 시 — 바로 타이머 재개
    func cancelExit() {
        resume()
    }

    // MARK: - 포맷팅

    /// "00:23:41" 형식
    var formattedElapsed: String {
        let total = Int(elapsed)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - 문장/이미지 기록

    /// 텍스트 또는 이미지 Quote 저장
    func saveQuote(contentType: QuoteContentType, text: String? = nil, imageData: Data? = nil) {
        let quote = Quote(
            libraryBookId: book.id,
            contentType: contentType,
            textContent: text,
            imageData: imageData
        )
        do {
            try repository.addQuote(quote, to: book.id)
            logger.info("Quote 저장 완료: \(contentType.rawValue)")
        } catch {
            logger.error("Quote 저장 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 세션 저장

    private func saveSessionIfNeeded() {
        let duration = elapsed
        guard duration >= minimumSessionDuration else {
            logger.info("독서 시간 \(Int(duration))초 — 최소 기준(60초) 미달, 세션 저장 생략")
            return
        }

        guard let startTime = sessionStartTime else {
            logger.warning("sessionStartTime이 nil — 세션 저장 불가")
            return
        }

        let session = ReadingSession(
            libraryBookId: book.id,
            startTime: startTime,
            endTime: Date(),
            duration: duration
        )

        do {
            try repository.addSession(session, to: book.id)
            logger.info("세션 저장 완료: \(Int(duration))초")
        } catch {
            // PRD: 저장 실패 시 에러 로그만 기록, UI 에러 표시 안 함
            logger.error("세션 저장 실패: \(error.localizedDescription)")
        }
    }
}
