//
//  LibraryTabView.swift
//  Booktory
//
//  서재 탭 — 책 목록 + 필터 (02-library-tab 구현 예정)
//

import SwiftUI

struct LibraryTabView: View {
    var body: some View {
        NavigationStack {
            Text("서재 탭")
                .navigationTitle("서재")
        }
    }
}

#Preview {
    LibraryTabView()
}
