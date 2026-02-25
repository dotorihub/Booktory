//
//  APIEndpoint.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import Foundation

struct APIEndpoint {
    let path: String
    var method: String = "GET"
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?

    func makeRequest(baseURL: URL) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.path = components.path.appending(path)
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body
        return request
    }
}

private extension String {
    func appending(_ pathComponent: String) -> String {
        if self.hasSuffix("/") {
            if pathComponent.hasPrefix("/") {
                return self + pathComponent.dropFirst()
            } else {
                return self + pathComponent
            }
        } else {
            if pathComponent.hasPrefix("/") {
                return self + pathComponent
            } else {
                return self + "/" + pathComponent
            }
        }
    }
}

