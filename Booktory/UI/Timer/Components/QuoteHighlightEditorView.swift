//
//  QuoteHighlightEditorView.swift
//  Booktory
//
//  촬영한 사진 위에 PencilKit 캔버스를 오버레이하여 강조 / 필기할 수 있는 편집기.
//  도구: 노란색 형광펜(반투명, 굵기 24pt 고정), 검정 일반펜(굵기 4pt 고정), 지우개. 손가락 입력 허용.
//  저장 시 사진과 드로잉을 합성하여 단일 UIImage로 반환한다.
//

import SwiftUI
import UIKit
import PencilKit

struct QuoteHighlightEditorView: View {

    let image: UIImage
    let onCancel: () -> Void
    let onSave: (UIImage) -> Void

    @State private var canvas = PKCanvasView()
    @State private var tool: EditorTool = .highlighter

    /// 노란색 형광펜 — 굵기 고정 (PRD 요구사항).
    /// PKInkingTool(.marker)의 기본 반투명 효과에 alpha를 추가로 곱해 책 페이지 글자가 더 잘 보이도록 한다.
    private let highlighterColor: UIColor = UIColor.systemYellow.withAlphaComponent(0.4)
    private let highlighterWidth: CGFloat = 24

    /// 검정 일반펜 — 굵기 고정.
    private let penColor: UIColor = UIColor.black
    private let penWidth: CGFloat = 4

    enum EditorTool {
        case highlighter
        case pen
        case eraser
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()

                    let displaySize = aspectFitSize(image.size, in: geometry.size)

                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                        PKCanvasRepresentable(
                            canvas: $canvas,
                            tool: tool,
                            highlighterColor: highlighterColor,
                            highlighterWidth: highlighterWidth,
                            penColor: penColor,
                            penWidth: penWidth
                        )
                    }
                    .frame(width: displaySize.width, height: displaySize.height)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: onCancel)
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 16) {
                        toolButton(
                            tool: .highlighter,
                            systemImage: "highlighter",
                            label: "형광펜"
                        )
                        toolButton(
                            tool: .pen,
                            systemImage: "pencil.tip",
                            label: "펜"
                        )
                        toolButton(
                            tool: .eraser,
                            systemImage: "eraser",
                            label: "지우개"
                        )
                        Button {
                            canvas.undoManager?.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .accessibilityLabel("실행 취소")
                        Button {
                            canvas.undoManager?.redo()
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                        }
                        .accessibilityLabel("다시 실행")
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let composed = renderComposite()
                        onSave(composed)
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Tool button

    private func toolButton(
        tool selectedTool: EditorTool,
        systemImage: String,
        label: String
    ) -> some View {
        Button {
            tool = selectedTool
        } label: {
            Image(systemName: systemImage)
                .foregroundStyle(tool == selectedTool ? .yellow : .white)
        }
        .accessibilityLabel(label)
    }

    // MARK: - Composite rendering

    /// 원본 이미지 크기에 맞춰 드로잉을 합성한 단일 UIImage 생성.
    /// 캔버스 좌표계를 이미지 좌표계로 환산하기 위해 image.size 기준으로 렌더한다.
    /// `format.scale = 1`로 고정 — 기본값(스크린 스케일 3x)이면 카메라 원본(4032×3024) 합성 시
    ///  ≈4GB 픽셀 버퍼가 필요해져 OOM으로 앱이 강제 종료된다.
    /// `opaque = true`로 알파 채널 제거 → 메모리 추가 절약 + JPEG 품질에 유리.
    private func renderComposite() -> UIImage {
        let imageSize = image.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        let canvasBounds = canvas.bounds

        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: imageSize))

            // 캔버스 드로잉을 image 크기로 스케일하여 그린다 — bounds.zero일 경우는 빈 이미지로 안전 처리
            guard canvasBounds.width > 0, canvasBounds.height > 0 else { return }

            let drawing = canvas.drawing
            let scaleX = imageSize.width / canvasBounds.width
            let scaleY = imageSize.height / canvasBounds.height

            context.cgContext.saveGState()
            context.cgContext.scaleBy(x: scaleX, y: scaleY)
            let drawingImage = drawing.image(from: canvasBounds, scale: 1)
            drawingImage.draw(in: canvasBounds)
            context.cgContext.restoreGState()
        }
    }

    /// 컨테이너 안에서 이미지를 aspect-fit 했을 때의 표시 크기.
    private func aspectFitSize(_ source: CGSize, in container: CGSize) -> CGSize {
        guard source.width > 0, source.height > 0 else { return .zero }
        let scale = min(container.width / source.width, container.height / source.height)
        return CGSize(width: source.width * scale, height: source.height * scale)
    }
}

// MARK: - PKCanvasView SwiftUI bridge

private struct PKCanvasRepresentable: UIViewRepresentable {

    @Binding var canvas: PKCanvasView
    let tool: QuoteHighlightEditorView.EditorTool
    let highlighterColor: UIColor
    let highlighterWidth: CGFloat
    let penColor: UIColor
    let penWidth: CGFloat

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput   // 손가락 + Apple Pencil 모두 허용
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        applyTool(to: canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        applyTool(to: uiView)
    }

    private func applyTool(to canvas: PKCanvasView) {
        switch tool {
        case .highlighter:
            // marker는 반투명 형광펜 효과 — 책 페이지 텍스트가 살아있도록
            canvas.tool = PKInkingTool(.marker, color: highlighterColor, width: highlighterWidth)
        case .pen:
            // 일반 볼펜 — 불투명 검정선
            canvas.tool = PKInkingTool(.pen, color: penColor, width: penWidth)
        case .eraser:
            canvas.tool = PKEraserTool(.bitmap)
        }
    }
}
