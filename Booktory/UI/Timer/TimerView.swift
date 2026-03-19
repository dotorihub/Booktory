//
//  TimerView.swift
//  Booktory
//
//  Created by 김지현 on 2/11/26.
//
//  독서 타이머 화면.
//  타이머 시작/일시정지/재개, 나가기 시 세션 저장을 처리한다.
//  백그라운드 나가도 Date 기반 계산으로 정확한 경과 시간을 유지한다.
//

import SwiftUI
import Combine

struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    /// 문장 기록 시트 표시
    @State private var showTextInput: Bool = false
    /// 이미지 기록 시트 표시
    @State private var showImagePicker: Bool = false

    // 매초마다 UI 업데이트용 Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(book: LibraryBook, repository: any LibraryRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: TimerViewModel(
            book: book,
            repository: repository
        ))
    }

    var body: some View {
        VStack(spacing: 40) {
            exitButton

            bookInfoSection

            Spacer()

            quoteButtons

            timerSection
        }
        .padding(.top, 16)
        .padding(.bottom, 80)
        .onAppear {
            viewModel.start()
        }
        .onReceive(timer) { _ in
            viewModel.tick()
        }
        .sheet(isPresented: $showTextInput) {
            QuoteTextInputView { text in
                viewModel.saveQuote(contentType: .text, text: text)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            QuoteImagePickerView { imageData in
                viewModel.saveQuote(contentType: .image, imageData: imageData)
            }
        }
        .alert("독서를 종료할까요?", isPresented: $viewModel.showExitConfirm) {
            Button("계속 읽기", role: .cancel) {
                viewModel.cancelExit()
            }
            Button("종료하기") {
                viewModel.confirmExit()
                dismiss()
            }
        } message: {
            let minutes = Int(viewModel.elapsed) / 60
            if minutes >= 1 {
                Text("\(minutes)분 동안 읽었어요. 종료하면 독서 기록이 저장됩니다.")
            } else {
                Text("1분 미만의 독서는 기록되지 않습니다.")
            }
        }
    }

    // MARK: - 나가기 버튼

    private var exitButton: some View {
        HStack {
            Spacer()
            Button {
                if viewModel.requestExit() {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            .accessibilityLabel("나가기")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 책 정보

    private var bookInfoSection: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: viewModel.book.coverURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    bookPlaceholder
                case .empty:
                    ProgressView()
                        .frame(width: 120, height: 180)
                @unknown default:
                    bookPlaceholder
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 12)

            Text(viewModel.book.title)
                .multilineTextAlignment(.center)
                .font(.title2.bold())
                .lineLimit(2)

            Text(viewModel.book.author)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Placeholder

    private var bookPlaceholder: some View {
        Image(systemName: "book.closed")
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
            .frame(width: 120, height: 180)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - 문장/이미지 기록 버튼

    private var quoteButtons: some View {
        HStack(spacing: 24) {
            Button {
                showTextInput = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 20))
                    Text("문장 기록")
                        .font(.caption2)
                }
                .foregroundStyle(.primary)
                .frame(width: 60, height: 52)
            }
            .accessibilityLabel("문장 기록")

            Button {
                showImagePicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                    Text("사진 기록")
                        .font(.caption2)
                }
                .foregroundStyle(.primary)
                .frame(width: 60, height: 52)
            }
            .accessibilityLabel("사진 기록")
        }
        .padding(.bottom, 8)
    }

    // MARK: - 타이머 + 제어 버튼

    private var timerSection: some View {
        VStack(spacing: 20) {
            Text(viewModel.formattedElapsed)
                .font(.system(size: 44, weight: .bold, design: .monospaced))

            switch viewModel.timerState {
            case .idle:
                EmptyView()
            case .running:
                Button(action: { viewModel.pause() }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .accessibilityLabel("일시정지")
            case .paused:
                Button(action: { viewModel.resume() }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .accessibilityLabel("재개")
            }
        }
    }
}
