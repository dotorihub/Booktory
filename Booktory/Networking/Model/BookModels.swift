//
//  BookModels.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import Foundation

// Naver Books API response model
// https://developers.naver.com/docs/serviceapi/search/book/book.md

struct BookSearchResponse: Decodable {
    let lastBuildDate: String?
    let total: Int
    let start: Int
    let display: Int
    let items: [NaverBookItem]
}

struct NaverBookItem: Decodable {
    let title: String?
    let link: String?
    let image: String?
    let author: String?
    // price 필드는 공식 문서에는 있으나, 응답에 없을 수 있어 제거하거나 옵셔널로 두되 사용하지 않음
    // let price: String?
    let discount: String?
    let publisher: String?
    let pubdate: String?
    let isbn: String?
    let description: String?
}

// App-facing Book model used by the UI
struct Book: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let publisher: String?
    let imageURL: URL?
    let linkURL: URL?
    let isbn: String?
    let description: String?

    init(from naver: NaverBookItem) {
        // Naver wraps some fields with HTML tags; strip basic tags
        func stripHTML(_ s: String) -> String {
            s.replacingOccurrences(of: "<b>", with: "")
             .replacingOccurrences(of: "</b>", with: "")
             .replacingOccurrences(of: "&quot;", with: "\"")
        }

        let rawTitle = naver.title ?? ""
        let rawAuthor = naver.author ?? ""

        self.title = stripHTML(rawTitle)
        self.author = stripHTML(rawAuthor)
        self.publisher = (naver.publisher?.isEmpty == false) ? naver.publisher : nil
        self.imageURL = URL(string: naver.image ?? "")
        self.linkURL = URL(string: naver.link ?? "")
        self.isbn = (naver.isbn?.isEmpty == false) ? naver.isbn : nil
        self.description = {
            guard let desc = naver.description, !desc.isEmpty else { return nil }
            return stripHTML(desc)
        }()

        // Use ISBN if available, otherwise link or title+author as fallback
        self.id = self.isbn ?? self.linkURL?.absoluteString ?? "\(self.title)-\(self.author)"
    }
}

