//
//  ReadingStatus.swift
//  Booktory
//

import Foundation

enum ReadingStatus: String, Codable, CaseIterable {
    case wantToRead   // 읽고 싶은
    case reading      // 읽고 있는
    case completed    // 완독한

    var label: String {
        switch self {
        case .wantToRead: return "읽고 싶은"
        case .reading:    return "읽고 있는"
        case .completed:  return "완독한"
        }
    }
}
