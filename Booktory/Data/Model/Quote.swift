//
//  Quote.swift
//  Booktory
//
//  독서 중 기록한 문장 또는 이미지.
//  타이머 화면에서 생성되며 책 상세 및 기록 탭에서 조회한다.
//

import Foundation
import SwiftData

@Model
final class Quote {
    var id: UUID
    var libraryBookId: UUID
    var contentType: QuoteContentType
    /// 텍스트 기록 내용 (contentType == .text일 때 사용)
    var textContent: String?
    /// 이미지 JPEG 데이터 (contentType == .image일 때 사용)
    var imageData: Data?
    var createdAt: Date

    var libraryBook: LibraryBook?

    init(
        libraryBookId: UUID,
        contentType: QuoteContentType,
        textContent: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = UUID()
        self.libraryBookId = libraryBookId
        self.contentType = contentType
        self.textContent = textContent
        self.imageData = imageData
        self.createdAt = Date()
    }
}
