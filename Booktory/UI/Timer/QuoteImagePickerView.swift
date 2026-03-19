//
//  QuoteImagePickerView.swift
//  Booktory
//
//  타이머 화면에서 책 페이지 사진을 선택하여 기록하는 시트.
//  PhotosPicker로 이미지를 선택하고 JPEG 0.7 압축 후 저장한다.
//

import SwiftUI
import PhotosUI

struct QuoteImagePickerView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoading: Bool = false
    @Environment(\.dismiss) private var dismiss

    let onSave: (Data) -> Void

    private let jpegCompression: CGFloat = 0.7

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                } else if isLoading {
                    ProgressView("이미지 불러오는 중...")
                        .frame(maxWidth: .infinity, maxHeight: 300)
                } else {
                    ContentUnavailableView(
                        "사진을 선택해주세요",
                        systemImage: "photo.on.rectangle",
                        description: Text("아래 버튼으로 책 페이지를 촬영하거나 선택하세요")
                    )
                }

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Label("사진 선택", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            .navigationTitle("이미지 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        guard let image = selectedImage,
                              let data = image.jpegData(compressionQuality: jpegCompression) else { return }
                        onSave(data)
                        dismiss()
                    }
                    .disabled(selectedImage == nil)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else {
                    selectedImage = nil
                    return
                }
                isLoading = true
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    QuoteImagePickerView { data in
        print("저장: \(data.count) bytes")
    }
}
