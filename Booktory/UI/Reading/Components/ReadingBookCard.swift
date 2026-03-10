//
//  ReadingBookCard.swift
//  Booktory
//
//  독서 탭의 책 카드. 표지·제목·저자·누적 시간 표시 및 [이어 읽기] 버튼.
//

import SwiftUI
import SwiftData

struct ReadingBookCard: View {
    let book: LibraryBook
    let totalSeconds: TimeInterval
    let onResume: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 표지 이미지
            AsyncImage(url: URL(string: book.coverURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    bookPlaceholder
                case .empty:
                    ProgressView()
                        .frame(width: 70, height: 100)
                @unknown default:
                    bookPlaceholder
                }
            }
            .frame(width: 70, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // 책 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formatReadingTime(totalSeconds))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button(action: onResume) {
                    Text("이어 읽기")
                        .fontWeight(.bold)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 1, x: -1, y: -1)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 2, y: 4)
    }

    // MARK: - Helpers

    private var bookPlaceholder: some View {
        Image(systemName: "book.closed")
            .font(.title)
            .foregroundStyle(.secondary)
            .frame(width: 70, height: 100)
            .background(Color.gray.opacity(0.1))
    }

    private func formatReadingTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return "총 \(hours)시간 \(String(format: "%02d", minutes))분 \(String(format: "%02d", secs))초"
        } else if minutes > 0 {
            return "총 \(String(format: "%02d", minutes))분 \(String(format: "%02d", secs))초"
        } else {
            return "총 \(String(format: "%02d", secs))초"
        }
    }
}
