//
//  BookSearchService.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import Foundation

protocol BookSearchService {
    func searchBooks(query: String, start: Int, display: Int) async throws -> [Book]
}

final class DefaultBookSearchService: BookSearchService {
    private let client: NetworkClient
    private let baseURL: URL
    private let clientID: String
    private let clientSecret: String

    init(client: NetworkClient = DefaultNetworkClient(),
         baseURL: URL = AppConfig.apiBaseURL,
         clientID: String = AppConfig.apiClientID,
         clientSecret: String = AppConfig.apiClientSecret) {
        self.client = client
        self.baseURL = baseURL
        self.clientID = clientID
        self.clientSecret = clientSecret
    }

    func searchBooks(query: String, start: Int = 1, display: Int = 20) async throws -> [Book] {
        guard !clientID.isEmpty, !clientSecret.isEmpty else {
            throw APIError.missingCredentials
        }

        let endpoint = APIEndpoint(
            path: "/v1/search/book.json",
            method: "GET",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "start", value: String(start)),
                URLQueryItem(name: "display", value: String(display))
            ],
            headers: [
                "X-Naver-Client-Id": clientID,
                "X-Naver-Client-Secret": clientSecret
            ]
        )

        let request = try endpoint.makeRequest(baseURL: baseURL)
        let (data, response) = try await client.perform(request)

        guard 200..<300 ~= response.statusCode else {
            throw APIError.statusCode(response.statusCode, data)
        }

        do {
            let decoded = try JSONDecoder().decode(BookSearchResponse.self, from: data)
            return decoded.items.map(Book.init(from:))
        } catch {
            // 디버깅 용도: 문제가 계속되면 raw JSON을 잠깐 출력해 확인
            // print(String(data: data, encoding: .utf8) ?? "Invalid UTF8")
            throw APIError.decodingFailed(underlying: error)
        }
    }
}

