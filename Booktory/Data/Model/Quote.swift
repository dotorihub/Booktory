//
//  Quote.swift
//  Booktory
//
//  독서 중 기록한 텍스트(문장).
//  타이머 화면에서 두 가지 경로로 생성된다:
//   - 직접 입력: QuoteTextInputView
//   - 사진 OCR: 카메라 → crop → Vision 텍스트 추출 → 편집 → 저장
//
//  히스토리:
//   - v1: 텍스트 또는 이미지(JPEG)를 contentType으로 구분해 저장
//   - v2: 이미지 저장 제거 — 사진은 OCR을 위한 임시 입력일 뿐, 영구 저장은 텍스트만 (현재)
//

import Foundation
import SwiftData

@Model
final class Quote {
    var id: UUID
    var libraryBookId: UUID
    /// 기록된 문장. v1 잔여 데이터(이미지만 있던 quote)는 nil로 남을 수 있어 옵셔널 유지.
    var textContent: String?
    var createdAt: Date

    var libraryBook: LibraryBook?

    init(
        libraryBookId: UUID,
        textContent: String
    ) {
        self.id = UUID()
        self.libraryBookId = libraryBookId
        self.textContent = textContent
        self.createdAt = Date()
    }
}
