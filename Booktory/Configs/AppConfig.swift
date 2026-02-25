//
//  AppConfig.swift
//  Booktory
//
//  Created by 김지현 on 2/25/26.
//

import Foundation

enum AppConfig {
    static var apiBaseURL: URL {
        // Info.plist에 API_BASE_URL이 없으면 네이버 오픈API 기본값 사용
        let base = Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? "https://openapi.naver.com"
        return URL(string: base)!
    }

    static var apiClientID: String {
        Bundle.main.infoDictionary?["API_CLIENT_ID"] as? String ?? ""
    }

    static var apiClientSecret: String {
        Bundle.main.infoDictionary?["API_CLIENT_SECRET"] as? String ?? ""
    }
}
