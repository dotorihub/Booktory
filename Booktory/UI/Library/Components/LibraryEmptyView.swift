//
//  LibraryEmptyView.swift
//  Booktory
//

import SwiftUI

struct LibraryEmptyView: View {
    let filter: ReadingStatus?
    /// 전체 탭에서만 사용. [책 보러 가기] 탭 시 검색 탭으로 전환.
    var onSearchTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundStyle(.quaternary)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if filter == nil, let onSearchTap {
                Button(action: onSearchTap) {
                    Text("책 보러 가기")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(20)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 필터별 콘텐츠

    private var iconName: String {
        switch filter {
        case .none:       return "books.vertical"
        case .reading:    return "book"
        case .completed:  return "checkmark.seal"
        case .wantToRead: return "bookmark"
        }
    }

    private var title: String {
        switch filter {
        case .none:       return "서재가 비어 있어요"
        case .reading:    return "읽고 있는 책이 없어요"
        case .completed:  return "완독한 책이 없어요"
        case .wantToRead: return "읽고 싶은 책이 없어요"
        }
    }

    private var subtitle: String {
        switch filter {
        case .none:       return "마음에 드는 책을 찾아\n서재에 추가해 보세요"
        case .reading:    return "서재에서 읽고 싶은 책을\n바로 읽기로 시작해 보세요"
        case .completed:  return "독서를 완료하면\n여기에 기록돼요"
        case .wantToRead: return "나중에 읽고 싶은 책을\n저장해 보세요"
        }
    }
}

// MARK: - Preview

#Preview("전체 비어있음") {
    LibraryEmptyView(filter: nil) {
        print("책 보러 가기 탭됨")
    }
}

#Preview("읽고 있는 없음") {
    LibraryEmptyView(filter: .reading)
}

#Preview("완독한 없음") {
    LibraryEmptyView(filter: .completed)
}

#Preview("읽고 싶은 없음") {
    LibraryEmptyView(filter: .wantToRead)
}
