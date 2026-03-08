//
//  ReadingSession.swift
//  Booktory
//

import Foundation
import SwiftData

// MARK: - ReadingSession

/// 타이머 1회 실행 기록.
/// 사용자가 [이어 읽기]를 누르고 [나가기]를 누를 때마다 1개 생성된다.
@Model
final class ReadingSession {

    // MARK: Stored Properties

    var id: UUID
    var libraryBookId: UUID   // LibraryBook 외래키 (직접 참조 불가 시 fallback용)
    var startTime: Date
    var endTime: Date

    /// 실제 독서 시간 (초 단위). 일시정지 구간 제외.
    /// endTime - startTime 이 아님에 주의.
    var duration: TimeInterval

    @Relationship
    var libraryBook: LibraryBook?

    // MARK: Init

    init(
        libraryBookId: UUID,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval
    ) {
        self.id = UUID()
        self.libraryBookId = libraryBookId
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }
}

// MARK: - Formatted Properties

extension ReadingSession {

    /// "오전/오후 HH:mm" 형태의 시작 시간 문자열
    var formattedStartTime: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }

    /// "yyyy.MM.dd" 형태의 날짜 문자열
    var formattedDate: String {
        startTime.formatted(.dateTime.year().month().day())
    }
}
