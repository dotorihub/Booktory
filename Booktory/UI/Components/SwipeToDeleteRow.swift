//
//  SwipeToDeleteRow.swift
//  Booktory
//
//  왼쪽으로 스와이프하면 삭제 버튼이 나타나는 범용 래퍼.
//  List 없이 ScrollView + VStack 안에서도 동작한다.
//

import SwiftUI

struct SwipeToDeleteRow<Content: View>: View {
    let content: Content
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    private let buttonWidth: CGFloat = 72

    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button {
                withAnimation(.spring(response: 0.3)) { offset = 0 }
                onDelete()
            } label: {
                ZStack {
                    Color.red
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(width: buttonWidth)
            }

            content
                .background(Color(.systemBackground))
                .offset(x: offset)
                .animation(.interactiveSpring(response: 0.3), value: offset)
        }
        .clipped()
        .simultaneousGesture(
            DragGesture(minimumDistance: 15, coordinateSpace: .local)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard abs(dx) > abs(dy) else { return }
                    offset = min(0, max(dx + (offset == -buttonWidth ? -buttonWidth : 0), -buttonWidth))
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = value.translation.width < -(buttonWidth / 2) ? -buttonWidth : 0
                    }
                }
        )
    }
}
