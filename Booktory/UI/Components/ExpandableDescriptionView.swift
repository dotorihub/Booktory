//
//  ExpandableDescriptionView.swift
//  Booktory
//
//  텍스트를 4줄까지 표시하고, 말줄임 시 더보기/접기 토글을 제공하는 공용 컴포넌트.
//  BookDetailView, LibraryDetailView 등에서 책 소개 표시에 사용한다.
//

import SwiftUI

struct ExpandableDescriptionView: View {
    let text: String
    @State private var isExpanded = false
    @State private var isTruncated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.body)
                .lineLimit(isExpanded ? nil : 4)
                .background(truncationDetector)

            if isTruncated || isExpanded {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "접기" : "더 보기")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onPreferenceChange(TruncationPreferenceKey.self) { isTruncated = $0 }
    }

    /// 4줄 제한 높이와 전체 높이를 비교해 말줄임 여부를 PreferenceKey로 전달한다.
    private var truncationDetector: some View {
        GeometryReader { limitedGeo in
            Text(text)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .hidden()
                .background(
                    GeometryReader { fullGeo in
                        Color.clear.preference(
                            key: TruncationPreferenceKey.self,
                            value: fullGeo.size.height > limitedGeo.size.height + 1
                        )
                    }
                )
        }
    }
}

private struct TruncationPreferenceKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
