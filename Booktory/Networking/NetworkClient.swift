//
//  NetworkClient.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import Foundation

protocol NetworkClient {
    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

final class DefaultNetworkClient: NetworkClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            return (data, http)
        } catch {
            // 취소는 실패로 래핑하지 않고 그대로 전파
            if Task.isCancelled {
                throw CancellationError()
            }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw urlError
            }
            throw APIError.requestFailed(underlying: error)
        }
    }
}
