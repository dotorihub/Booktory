//
//  ExtractedTextEditorView.swift
//  Booktory
//
//  OCR로 추출된 텍스트를 prefill해 사용자에게 편집을 받는 화면.
//  사용자가 [저장]하면 부모(QuoteImagePickerView)를 통해 텍스트 Quote로 영구 저장된다.
//

import SwiftUI

struct ExtractedTextEditorView: View {
    @State var text: String
    @FocusState private var isFocused: Bool

    let onCancel: () -> Void
    let onSave: (String) -> Void

    init(initialText: String, onCancel: @escaping () -> Void, onSave: @escaping (String) -> Void) {
        _text = State(initialValue: initialText)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .padding()
            }
            .navigationTitle("문장 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

#Preview {
    ExtractedTextEditorView(
        initialText: "OCR로 추출된 샘플 문장입니다.\n여러 줄 가능.",
        onCancel: { print("cancel") },
        onSave: { print("save: \($0)") }
    )
}
