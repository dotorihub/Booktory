//
//  LibraryBook+Book.swift
//  Booktory
//
//  Naver API 검색 결과(Book)를 서재 모델(LibraryBook)로 변환하는 편의 이니셜라이저.
//

import Foundation

extension LibraryBook {
    /// Naver API 검색 결과를 서재 모델로 변환한다.
    /// - Parameters:
    ///   - book: Naver Books API 검색 모델
    ///   - status: 서재에 저장할 초기 독서 상태
    convenience init(from book: Book, status: ReadingStatus) {
        self.init(
            isbn: book.id,
            title: book.title,
            author: book.author,
            publisher: book.publisher ?? "",
            coverURL: book.imageURL?.absoluteString ?? "",
            bookDescription: book.description ?? "",
            status: status
        )
    }
}
