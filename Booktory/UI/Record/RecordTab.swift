//
//  RecordTab.swift
//  Booktory
//
//  기록 탭 — 독서 일지, 메모, 감상 기록.
//

import SwiftUI

struct RecordTabView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "기록",
                systemImage: "note.text",
                description: Text("독서 일지와 메모를 기록하는 공간입니다.")
            )
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RecordTabView()
}
