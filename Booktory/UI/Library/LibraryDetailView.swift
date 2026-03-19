//
//  LibraryDetailView.swift
//  Booktory
//
//  서재 책 상세 화면.
//  책 메타 정보, 독서 통계, 세션 히스토리를 표시하고
//  상태 변경(읽기 시작/완독)과 삭제 액션을 제공한다.
//

import SwiftUI
import SwiftData

// MARK: - Public Entry Point

/// 환경에서 repository를 읽어 ViewModel을 생성하는 진입 뷰.
struct LibraryDetailView: View {
    let book: LibraryBook
    @Environment(\.libraryRepository) private var repository

    var body: some View {
        LibraryDetailContentView(
            viewModel: LibraryDetailViewModel(book: book, repository: repository)
        )
    }
}

// MARK: - Content View

private struct LibraryDetailContentView: View {
    @StateObject var viewModel: LibraryDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isDeleted {
                // 삭제 후 dismiss 전까지 빈 화면 표시 (detached 객체 접근 방지)
                Color.clear
            } else {
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        coverImage
                        bookInfo
                        Divider().padding(.horizontal)
                        statsSection
                        Divider().padding(.horizontal)
                        descriptionSection
                        sessionHistory
                        quoteHistory
                    }
                    .padding(.vertical, 20)
                }
                .toolbar { deleteToolbarItem }
                .safeAreaInset(edge: .bottom) { actionButton }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadSessions() }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .alert("서재에서 삭제", isPresented: $viewModel.showDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task { await viewModel.deleteBook() }
            }
        } message: {
            Text("서재에서 삭제하면 모든 독서 기록도 함께 삭제됩니다.")
        }
        .alert("오류", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 책 표지

    private var coverImage: some View {
        AsyncImage(url: URL(string: viewModel.book.coverURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "book.closed.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.quaternary)
            case .empty:
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: 160)
        .aspectRatio(contentMode: .fit)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        .padding(.horizontal)
    }

    // MARK: - 제목 / 저자 / 출판사

    private var bookInfo: some View {
        VStack(spacing: 6) {
            Text(viewModel.book.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Text(viewModel.book.author)
                if !viewModel.book.publisher.isEmpty {
                    Text("·")
                    Text(viewModel.book.publisher)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    // MARK: - 독서 통계

    private var statsSection: some View {
        VStack(spacing: 16) {
            // 총 독서 시간 + 횟수
            HStack {
                StatItem(title: "총 독서 시간", value: viewModel.formattedTotalTime)
                Divider().frame(height: 40)
                StatItem(title: "독서 횟수", value: "\(viewModel.sessionCount)회")
            }

            // 날짜 정보
            HStack {
                StatItem(title: "추가일", value: viewModel.formattedAddedAt)
                if viewModel.book.status != .wantToRead {
                    StatItem(title: "시작일", value: viewModel.formattedStartedAt)
                }
                if viewModel.book.status == .completed {
                    StatItem(title: "완독일", value: viewModel.formattedCompletedAt)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 책 소개

    @ViewBuilder
    private var descriptionSection: some View {
        if !viewModel.book.bookDescription.isEmpty {
            ExpandableDescriptionView(text: viewModel.book.bookDescription)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    // MARK: - 세션 히스토리

    private var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("독서 기록")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.sessions.isEmpty {
                Text("아직 독서 기록이 없어요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(viewModel.sessions, id: \.id) { session in
                    SessionRow(session: session)
                }
            }
        }
    }

    // MARK: - 문장 기록

    private var quoteHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("문장 기록")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.quotes.isEmpty {
                Text("아직 문장 기록이 없어요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(viewModel.quotes, id: \.id) { quote in
                    QuoteRowView(quote: quote)
                }
            }
        }
    }

    // MARK: - 상태별 액션 버튼 (하단 고정)

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.book.status {
        case .wantToRead:
            bottomButton(label: "읽기 시작", color: .green) {
                Task { await viewModel.startReading() }
            }
        case .reading:
            bottomButton(label: "완독으로 표시", color: .accentColor) {
                Task { await viewModel.markAsCompleted() }
            }
        case .completed:
            EmptyView()
        }
    }

    private func bottomButton(
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    // MARK: - Toolbar 삭제 메뉴

    @ToolbarContentBuilder
    private var deleteToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button(role: .destructive) {
                    viewModel.showDeleteConfirm = true
                } label: {
                    Label("서재에서 삭제", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .accessibilityLabel("더보기")
            }
        }
    }
}

// MARK: - 통계 아이템

private struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 세션 행

private struct SessionRow: View {
    let session: ReadingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startTime.formatted(
                    .dateTime.year().month(.twoDigits).day(.twoDigits)
                ))
                .font(.subheadline)

                Text(session.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedDuration(session.duration))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(String(format: "%02d", minutes))분"
        }
        return "\(minutes)분"
    }
}

// MARK: - Preview

#Preview("읽고 있는 책") {
    NavigationStack {
        LibraryDetailView(book: LibraryBook.previewItems[0])
    }
    .environment(\.libraryRepository, PreviewLibraryRepository.populated())
}

#Preview("읽고 싶은 책") {
    NavigationStack {
        LibraryDetailView(book: LibraryBook.previewItems[4])
    }
    .environment(\.libraryRepository, PreviewLibraryRepository.populated())
}

#Preview("완독한 책") {
    NavigationStack {
        LibraryDetailView(book: LibraryBook.previewItems[2])
    }
    .environment(\.libraryRepository, PreviewLibraryRepository.populated())
}
