//
//  QuoteImagePickerView.swift
//  Booktory
//
//  타이머 화면에서 책 페이지를 촬영하고 형광펜으로 강조 표시한 뒤 기록하는 시트.
//  카메라 촬영 → 형광펜 편집 → 앨범 저장 + 앱 저장 흐름을 한 컨테이너에서 관리한다.
//
//  히스토리:
//   - v1: PhotosPicker로 앨범에서 선택만 지원
//   - v2: 카메라 촬영 + PencilKit 형광펜 드로잉 + 앨범 저장 (현재)
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

struct QuoteImagePickerView: View {

    let onSave: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var capturedImage: UIImage?
    /// 카메라 시트 표시 여부 — 화면 진입 시 자동 오픈
    @State private var showCamera: Bool = false
    /// 카메라 권한 거부 시 설정 앱 유도 알럿
    @State private var showCameraSettingsAlert: Bool = false
    /// 앨범 권한이 이전에 거부된 경우 (다시 요청 불가) 노출 알럿
    @State private var showPhotoPermissionAlert: Bool = false
    /// 앨범 저장 실패 등 일반 에러 알럿
    @State private var showSaveErrorAlert: Bool = false
    @State private var saveErrorMessage: String = ""

    private let jpegCompression: CGFloat = 0.8

    var body: some View {
        Group {
            if let image = capturedImage {
                QuoteHighlightEditorView(
                    image: image,
                    onCancel: { dismiss() },
                    onSave: handleSave
                )
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .task {
            await requestCameraAndPresent()
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: handleCameraDismiss) {
            CameraCaptureView { image in
                capturedImage = image
            }
            .ignoresSafeArea()
        }
        .alert("카메라 권한이 필요합니다", isPresented: $showCameraSettingsAlert) {
            Button("설정 열기") { openAppSettings() }
            Button("취소", role: .cancel) { dismiss() }
        } message: {
            Text("설정 → 북토리에서 카메라 접근을 허용해주세요.")
        }
        .alert("사진 앨범 권한이 필요합니다", isPresented: $showPhotoPermissionAlert) {
            Button("설정 열기") { openAppSettings() }
            Button("앱에만 저장") { saveToAppOnly() }
        } message: {
            Text("앨범 저장 권한이 거부되어 있어요. 설정에서 허용하거나, 앱에만 저장할 수 있습니다.")
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(saveErrorMessage)
        }
    }

    // MARK: - 카메라 권한 처리

    /// 화면 진입 시 카메라 권한 상태 확인 후, 가능하면 카메라 시트를 자동 오픈한다.
    /// - notDetermined: 시스템 권한 팝업 → 허용 시 카메라 오픈, 거부 시 시트 dismiss
    /// - authorized: 카메라 오픈
    /// - denied/restricted: 설정 앱 유도 알럿 (재요청 불가)
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

    /// 카메라 시트가 닫혔는데 사진을 못 가져온 경우 → 사용자가 취소한 것으로 간주하고 전체 dismiss.
    private func handleCameraDismiss() {
        if capturedImage == nil {
            dismiss()
        }
    }

    // MARK: - 저장

    /// 편집기에서 [저장] 누른 시점.
    /// 1) 앱 DB 저장 (onSave 콜백) — 항상 수행
    /// 2) 앨범 저장 — 권한 상태에 따라 분기 (거부 알럿 시에는 1)도 미루고 사용자 선택 대기)
    private func handleSave(_ finalImage: UIImage) {
        guard let data = finalImage.jpegData(compressionQuality: jpegCompression) else {
            saveErrorMessage = "이미지 변환에 실패했어요."
            showSaveErrorAlert = true
            return
        }

        // 앨범 저장 권한 흐름
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                Task { @MainActor in
                    if newStatus == .authorized || newStatus == .limited {
                        await saveToAlbum(finalImage)
                    }
                    // 권한 거부됐어도 앱에는 저장
                    onSave(data)
                    dismiss()
                }
            }
        case .authorized, .limited:
            Task { @MainActor in
                await saveToAlbum(finalImage)
                onSave(data)
                dismiss()
            }
        case .denied, .restricted:
            // 시스템 팝업 재호출 불가 → 설정 유도 알럿. 앱 저장은 사용자 선택 대기.
            pendingImageData = data
            showPhotoPermissionAlert = true
        @unknown default:
            onSave(data)
            dismiss()
        }
    }

    /// 권한 알럿에서 [앱에만 저장] 선택한 경우.
    private func saveToAppOnly() {
        if let data = pendingImageData {
            onSave(data)
        }
        pendingImageData = nil
        dismiss()
    }

    /// 권한 거부 알럿 응답 대기 동안 임시 보관할 JPEG 데이터.
    @State private var pendingImageData: Data?

    /// PHPhotoLibrary로 앨범 저장. 실패해도 앱 저장은 별도로 진행됨.
    private func saveToAlbum(_ image: UIImage) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            // 앨범 저장 실패는 치명적이지 않음 — 로그만 남기고 진행
            print("앨범 저장 실패: \(error.localizedDescription)")
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        dismiss()
    }
}

#Preview {
    QuoteImagePickerView { data in
        print("저장: \(data.count) bytes")
    }
}
