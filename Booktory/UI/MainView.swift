//
//  MainView.swift
//  Booktory
//
//  Created by 김지현 on 2/9/26.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerMainView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "clock")
                }
                .tag(0)

            Text("내 기록")
                .tabItem {
                    Image(systemName: "book")
                }
                .tag(1)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
                .tag(2)

            Text("")
                .tabItem {
                    Image(systemName: "person")
                }
                .tag(3)
        }
    }
}

#Preview {
    MainView()
}
