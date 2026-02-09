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
            Text("독서")
                .tabItem {
                    Image(systemName: "clock")
                    Text("독서")
                }
            
            Text("내 기록")
                .tabItem {
                    Image(systemName: "person")
                    Text("내 기록")
                }
            
            Text("검색")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("탐색")
                }
            
            Text("설정 화면")
                .tabItem {
                    Image(systemName: "gear")
                    Text("설정")
                }
        }
    }
}

#Preview {
    MainView()
}
