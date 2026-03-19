//
//  QuoteTextInputView.swift
//  Booktory
//
//  타이머 화면에서 텍스트 문장을 기록하는 시트.
//

import SwiftUI

struct QuoteTextInputView: View {
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    let onSave: (String) -> Void

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
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

#Preview {
    QuoteTextInputView { text in
        print("저장: \(text)")
    }
}
