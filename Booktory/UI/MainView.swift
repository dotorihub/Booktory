//
//  MainView.swift
//  Booktory
//
//  Created by 김지현 on 2/9/26.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            TimerMainView()
                .tabItem {
                    Image(systemName: "clock")
                }
            
            Text("내 기록")
                .tabItem {
                    Image(systemName: "book")
                }
            
            Text("검색")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
            
            Text("")
                .tabItem {
                    Image(systemName: "person")
                }
        }
    }
}

#Preview {
    MainView()
}
