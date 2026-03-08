//
//  LibraryFilterTabView.swift
//  Booktory
//

import SwiftUI

struct LibraryFilterTabView: View {
    @Binding var selectedFilter: ReadingStatus?

    private let items: [(label: String, filter: ReadingStatus?)] = [
        ("전체",      nil),
        ("읽고 있는", .reading),
        ("완독한",    .completed),
        ("읽고 싶은", .wantToRead),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(items, id: \.label) { item in
                    FilterTabItem(
                        label: item.label,
                        isSelected: selectedFilter == item.filter
                    ) {
                        selectedFilter = item.filter
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - FilterTabItem

private struct FilterTabItem: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(label)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var filter: ReadingStatus? = nil
    LibraryFilterTabView(selectedFilter: $filter)
        .padding(.vertical, 8)
}
