//
//  ReadingSession.swift
//  Booktory
//

import Foundation
import SwiftData

@Model
final class ReadingSession {
    var id: UUID
    var libraryBookId: UUID
    var startTime: Date
    var endTime: Date
    /// 일시정지 구간을 제외한 실제 독서 시간 (초 단위)
    var duration: TimeInterval

    var libraryBook: LibraryBook?

    init(libraryBookId: UUID, startTime: Date, endTime: Date, duration: TimeInterval) {
        self.id = UUID()
        self.libraryBookId = libraryBookId
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }
}
