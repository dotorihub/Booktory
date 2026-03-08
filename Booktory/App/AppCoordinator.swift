//
//  AppCoordinator.swift
//  Booktory
//
//  탭 전환과 앱 수준 네비게이션을 담당하는 코디네이터.
//  EnvironmentObject로 전달하며, 하위 뷰는 이를 통해 탭을 전환한다.
//

import SwiftUI
import Combine

@MainActor
final class AppCoordinator: ObservableObject {

    enum Tab: Int, CaseIterable {
        case reading = 0
        case search  = 1
        case record  = 2
        case library = 3

        var title: String {
            switch self {
            case .reading: return "독서"
            case .search:  return "검색"
            case .record:  return "기록"
            case .library: return "서재"
            }
        }

        var icon: String {
            switch self {
            case .reading: return "book.fill"
            case .search:  return "magnifyingglass"
            case .record:  return "chart.bar.fill"
            case .library: return "books.vertical.fill"
            }
        }
    }

    @Published var selectedTab: Tab = .reading

    func switchTab(to tab: Tab) {
        selectedTab = tab
    }
}
