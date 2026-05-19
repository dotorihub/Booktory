//
//  QuoteImagePickerView.swift
//  Booktory
//
//  사진 기록 흐름 컨테이너 — 카메라 촬영 → crop 편집 → OCR → 텍스트 편집 → 저장.
//  최종 저장 데이터는 텍스트(`Quote.textContent`)이며 이미지는 영구 저장되지 않는다.
//
//  히스토리:
//   - v1: PhotosPicker로 앨범 선택
//   - v2: 카메라 촬영 + PencilKit 형광펜 + 앨범 저장
//   - v3: 카메라 → crop → Vision OCR → 텍스트 편집 → 텍스트 quote 저장 (현재)
//

import SwiftUI
import UIKit
import AVFoundation

struct QuoteImagePickerView: View {

    /// OCR/편집을 거친 최종 텍스트를 부모(TimerView)에 전달.
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Flow state

    /// 흐름의 현재 단계.
    private enum Stage {
        case awaitingCamera        // 카메라 권한 확인 + 시트 표시 대기
        case cropping(UIImage)     // crop 편집 중
        case extracting(UIImage)   // OCR 진행 중 (로딩)
        case editing(String)       // OCR 결과를 prefill한 텍스트 편집
    }

    @State private var stage: Stage = .awaitingCamera

    // MARK: - Camera presentation

    @State private var showCamera: Bool = false
    @State private var showCameraSettingsAlert: Bool = false

    // MARK: - OCR alerts

    @State private var showNoTextAlert: Bool = false
    @State private var showOCRErrorAlert: Bool = false
    @State private var ocrErrorMessage: String = ""

    var body: some View {
        Group {
            switch stage {
            case .awaitingCamera:
                Color.black.ignoresSafeArea()

            case .cropping(let image):
                PhotoCropEditorView(
                    image: image,
                    onCancel: { dismiss() },
                    onExtract: { cropped in
                        Task { await runOCR(on: cropped) }
                    }
                )

            case .extracting(let image):
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .opacity(0.3)
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.4)
                        Text("텍스트 추출 중…")
                            .foregroundStyle(.white)
                            .font(.callout)
                    }
                }

            case .editing(let initialText):
                ExtractedTextEditorView(
                    initialText: initialText,
                    onCancel: { dismiss() },
                    onSave: { text in
                        onSave(text)
                        dismiss()
                    }
                )
            }
        }
        .task {
            await requestCameraAndPresent()
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: handleCameraDismiss) {
            CameraCaptureView { image in
                stage = .cropping(image)
            }
            .ignoresSafeArea()
        }
        .alert("카메라 권한이 필요합니다", isPresented: $showCameraSettingsAlert) {
            Button("설정 열기") { openAppSettings() }
            Button("취소", role: .cancel) { dismiss() }
        } message: {
            Text("설정 → 북토리에서 카메라 접근을 허용해주세요.")
        }
        .alert("텍스트를 찾지 못했어요", isPresented: $showNoTextAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("이미지에서 인식 가능한 텍스트를 찾지 못했어요. 영역을 다시 조정해보세요.")
        }
        .alert("텍스트 추출 실패", isPresented: $showOCRErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(ocrErrorMessage)
        }
    }

    // MARK: - Camera 권한 처리

    @MainActor
    private func requestCameraAndPresent() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                showCamera = true
            } else {
                showCameraSettingsAlert = true
            }
        case .denied, .restricted:
            showCameraSettingsAlert = true
        @unknown default:
            showCameraSettingsAlert = true
        }
    }

    /// 카메라 시트가 닫혔는데 사진을 못 가져온 경우 (사용자 취소) → 전체 dismiss.
    private func handleCameraDismiss() {
        if case .awaitingCamera = stage {
            dismiss()
        }
    }

    // MARK: - OCR

    /// crop 화면에서 [텍스트 추출] 누른 시점.
    /// 결과가 있으면 편집 화면으로 전환, 없으면 알럿 후 crop 화면으로 복귀.
    private func runOCR(on image: UIImage) async {
        stage = .extracting(image)
        do {
            let text = try await OCRService.extractText(from: image)
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                stage = .cropping(image)
                showNoTextAlert = true
            } else {
                stage = .editing(trimmed)
            }
        } catch {
            stage = .cropping(image)
            ocrErrorMessage = error.localizedDescription
            showOCRErrorAlert = true
        }
    }

    // MARK: - Helpers

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        dismiss()
    }
}

#Preview {
    QuoteImagePickerView { text in
        print("저장: \(text)")
    }
}
