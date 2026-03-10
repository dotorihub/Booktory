//
//  ReadingEmptyView.swift
//  Booktory
//
//  독서 탭 빈 상태 화면. 읽고 있는 책이 없을 때 표시.
//

import SwiftUI

struct ReadingEmptyView: View {
    let onSearchTap: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.open")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityLabel("열린 책")

            Text("읽고 있는 책이 없어요")
                .font(.headline)

            Text("독서를 시작해보세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onSearchTap) {
                Label("책 검색하기", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ReadingEmptyView(onSearchTap: {})
}
