//
//  DaySessionList.swift
//  Booktory
//
//  선택된 날짜의 독서 세션 목록.
//  위클리/먼슬리 달력 하단에 공용으로 사용한다.
//

import SwiftUI

struct DaySessionList: View {
    let date: Date
    let sessions: [ReadingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                .font(.subheadline.bold())
                .padding(.horizontal)

            if sessions.isEmpty {
                emptyView
            } else {
                ForEach(sessions, id: \.id) { session in
                    SessionRow(session: session)
                }
            }
        }
    }

    private var emptyView: some View {
        Text("이 날은 독서를 하지 않았어요")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }
}

// MARK: - SessionRow

private struct SessionRow: View {
    let session: ReadingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // 책 제목은 libraryBook relationship이 있을 때 표시
                if let book = session.libraryBook {
                    Text(book.title)
                        .font(.subheadline)
                        .lineLimit(1)
                }

                Text(session.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(DurationFormatter.format(session.duration))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    DaySessionList(date: .now, sessions: [])
}
