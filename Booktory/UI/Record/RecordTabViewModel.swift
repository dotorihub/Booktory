//
//  RecordTabViewModel.swift
//  Booktory
//
//  기록 탭의 상태 관리 및 비즈니스 로직.
//  독서 통계 계산, 달력 데이터 그룹핑, 날짜 선택을 처리한다.
//

import Foundation
import Combine
import os

@MainActor
final class RecordTabViewModel: ObservableObject {

    // MARK: - 통계

    @Published private(set) var weeklyDuration: TimeInterval = 0
    @Published private(set) var totalDuration: TimeInterval = 0
    @Published private(set) var completedCount: Int = 0

    // MARK: - 달력

    enum CalendarMode: String, CaseIterable {
        case weekly
        case monthly
    }

    @Published var calendarMode: CalendarMode = .weekly
    @Published var selectedDate: Date = .now
    @Published var displayedMonth: Date = .now

    // MARK: - 데이터

    @Published private(set) var allSessions: [ReadingSession] = []

    private let repository: any LibraryRepositoryProtocol
    private let calendar = Calendar.current
    private let logger = Logger(subsystem: "com.booktory", category: "RecordTab")

    init(repository: any LibraryRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 공개 인터페이스

    /// 화면 진입 시 전체 데이터 로드
    func loadData() async {
        do {
            allSessions = try repository.fetchAllSessions()
            let books = try repository.fetchBy(status: .completed)
            completedCount = books.count
            computeStats()
        } catch {
            logger.error("기록 데이터 로드 실패: \(error.localizedDescription)")
        }
    }

    /// 먼슬리에서 이전 월로 이동
    func moveToPreviousMonth() {
        guard let previous = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }
        displayedMonth = previous
    }

    /// 먼슬리에서 다음 월로 이동 (미래 달 차단)
    func moveToNextMonth() {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }
        // 다음 달의 1일이 오늘보다 미래면 차단
        let nextMonth = calendar.dateInterval(of: .month, for: next)
        if let start = nextMonth?.start, start > Date.now { return }
        displayedMonth = next
    }

    /// 다음 달 이동이 가능한지 여부
    var canMoveToNextMonth: Bool {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth),
              let nextMonth = calendar.dateInterval(of: .month, for: next) else {
            return false
        }
        return nextMonth.start <= Date.now
    }

    // MARK: - 달력 데이터

    /// 선택된 날짜의 세션 목록
    func sessions(for date: Date) -> [ReadingSession] {
        allSessions.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    }

    /// 특정 날짜의 독서 depth (히트맵 농도)
    /// 0: 없음, 1: ~30분, 2: ~2시간, 3: 2시간 초과
    func readingDepth(for date: Date) -> Int {
        let daySessions = sessions(for: date)
        guard !daySessions.isEmpty else { return 0 }
        let total = daySessions.reduce(0.0) { $0 + $1.duration }
        switch total {
        case ..<1_800: return 1      // ~30분
        case ..<7_200: return 2      // ~2시간
        default: return 3            // 2시간+
        }
    }

    /// 이번 주 날짜 배열 (월~일)
    var currentWeekDates: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date.now) else {
            return []
        }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekInterval.start)
        }
    }

    /// 표시 중인 월의 날짜 그리드 (앞쪽 빈 셀 포함)
    var monthlyGridDates: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return []
        }
        let firstDay = monthInterval.start
        // 월요일 = 2, 일요일 = 1. 월요일 시작 기준 오프셋 계산
        let weekday = calendar.component(.weekday, from: firstDay)
        // 월요일=0, 화=1, ..., 일=6
        let offset = (weekday + 5) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30

        var grid: [Date?] = Array(repeating: nil, count: offset)
        for day in 0..<daysInMonth {
            grid.append(calendar.date(byAdding: .day, value: day, to: firstDay))
        }
        return grid
    }

    /// 표시 중인 월 타이틀 ("2026년 3월")
    var displayedMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }

    // MARK: - 책 컬러 도트 / 표지 카드

    /// 특정 날짜에 읽은 책들의 BookColor 배열 (중복 제거, colorIndex 오름차순)
    func bookColors(for date: Date) -> [BookColor] {
        let daySessions = sessions(for: date)
        // libraryBook 관계를 통해 책별로 중복 제거
        var seen = Set<UUID>()
        var colors: [(Int, BookColor)] = []
        for session in daySessions {
            guard let book = session.libraryBook, !seen.contains(book.id) else { continue }
            seen.insert(book.id)
            colors.append((book.colorIndex, book.bookColor))
        }
        return colors.sorted { $0.0 < $1.0 }.map(\.1)
    }

    /// 특정 날짜의 책별 독서 요약 (표지 카드용)
    func bookSummaries(for date: Date) -> [DayBookSummary] {
        let daySessions = sessions(for: date)
        // libraryBookId 기준으로 그룹핑
        var grouped: [UUID: (book: LibraryBook, duration: TimeInterval)] = [:]
        for session in daySessions {
            guard let book = session.libraryBook else { continue }
            if var entry = grouped[book.id] {
                entry.duration += session.duration
                grouped[book.id] = entry
            } else {
                grouped[book.id] = (book: book, duration: session.duration)
            }
        }
        return grouped.values
            .map { entry in
                DayBookSummary(
                    id: entry.book.id,
                    title: entry.book.title,
                    coverURL: entry.book.coverURL,
                    bookColor: entry.book.bookColor,
                    totalDuration: entry.duration
                )
            }
            .sorted { $0.bookColor.rawValue < $1.bookColor.rawValue }
    }

    // MARK: - Private

    private func computeStats() {
        totalDuration = allSessions.reduce(0.0) { $0 + $1.duration }

        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date.now) else {
            weeklyDuration = 0
            return
        }
        weeklyDuration = allSessions
            .filter { $0.startTime >= weekInterval.start && $0.startTime < weekInterval.end }
            .reduce(0.0) { $0 + $1.duration }
    }
}

// MARK: - 책별 독서 요약

struct DayBookSummary: Identifiable, Sendable {
    let id: UUID              // libraryBookId
    let title: String
    let coverURL: String
    let bookColor: BookColor
    let totalDuration: TimeInterval
}
