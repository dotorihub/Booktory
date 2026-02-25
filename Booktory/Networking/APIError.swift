//
//  APIError.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(underlying: Error)
    case invalidResponse
    case statusCode(Int, Data?)
    case decodingFailed(underlying: Error)
    case missingCredentials

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL 입니다."
        case .requestFailed(let underlying):
            return "요청이 실패했습니다: \(underlying.localizedDescription)"
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        case .statusCode(let code, _):
            return "서버 오류가 발생했습니다. 상태 코드: \(code)"
        case .decodingFailed(let underlying):
            return "데이터 디코딩에 실패했습니다: \(underlying.localizedDescription)"
        case .missingCredentials:
            return "API 인증 정보가 누락되었습니다."
        }
    }
}
