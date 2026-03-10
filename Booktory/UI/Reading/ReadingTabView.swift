//
//  ReadingTabView.swift
//  Booktory
//
//  독서 탭 — 읽고 있는 책 목록 + 타이머 진입점 (04-reading-tab 구현 예정)
//

import SwiftUI

struct ReadingTabView: View {
    var body: some View {
        NavigationStack {
            Text("독서 탭")
                .navigationTitle("독서")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ReadingTabView()
}
