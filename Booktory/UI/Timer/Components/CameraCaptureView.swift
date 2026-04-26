//
//  CameraCaptureView.swift
//  Booktory
//
//  UIImagePickerController(.camera)를 SwiftUI에서 사용하기 위한 래퍼.
//  앨범 선택은 지원하지 않고 촬영만 처리한다 — 책 페이지 촬영용 UX에 맞춰 단순화.
//

import SwiftUI
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {

    let onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        // sourceType은 호출 전에 카메라 가능 여부를 검증해야 함 — 호출자에서 권한 통과한 후만 진입.
        controller.sourceType = .camera
        controller.cameraCaptureMode = .photo
        controller.allowsEditing = false
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
