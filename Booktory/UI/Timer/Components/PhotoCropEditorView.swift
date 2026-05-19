//
//  PhotoCropEditorView.swift
//  Booktory
//
//  촬영한 이미지에서 텍스트 추출 영역을 잘라내기 위한 자유 비율 crop 편집기.
//  초기 진입 시 crop 영역은 이미지 전체 — 사용자가 모서리 핸들로 줄일 수 있다.
//  툴바: [취소] / [텍스트 추출]
//
//  좌표 변환:
//   - imageDisplayRect는 background GeometryReader 없이 image.size + geometry.size로 직접 계산.
//     (onAppear 타이밍 이슈를 피하기 위해 수학적 계산으로 대체)
//   - 화면 좌표(cropRect)에서 사용자 인터랙션 처리
//   - 저장 시점에 imageDisplayRect 기준으로 원본 이미지 좌표로 환산해 crop
//   - OCR 정확도를 위해 원본 해상도 유지 (다운샘플 안 함)
//

import SwiftUI
import UIKit

struct PhotoCropEditorView: View {

    let image: UIImage
    let onCancel: () -> Void
    /// 잘라낸 원본 해상도 이미지를 부모(QuoteImagePickerView)에 전달.
    let onExtract: (UIImage) -> Void

    /// 화면 표시 좌표계의 crop 영역. 첫 진입 시 .zero — onAppear에서 이미지 전체로 초기화.
    @State private var cropRect: CGRect = .zero
    /// 이미지가 aspect-fit으로 렌더된 화면 좌표계의 사각형.
    @State private var imageDisplayRect: CGRect = .zero
    /// 모서리/본체 드래그 시작 시점의 cropRect (translation 기준점)
    @State private var dragStartRect: CGRect = .zero

    private let cornerHandleSize: CGFloat = 28
    private let cornerVisualSize: CGFloat = 16
    private let minCropSide: CGFloat = 60

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                    // 어두운 오버레이 (crop 영역 제외)
                    dimOverlay(containerSize: geometry.size)

                    // crop 본체 + 모서리 핸들
                    cropFrame
                }
                // initial: true — 첫 렌더 시 geometry.size가 .zero일 수 있으므로
                // onAppear 대신 onChange를 써서 size 확정 시점에 초기화한다.
                .onChange(of: geometry.size, initial: true) { _, newSize in
                    let rect = computeDisplayRect(in: newSize)
                    guard rect != .zero else { return }
                    imageDisplayRect = rect
                    if cropRect == .zero {
                        cropRect = rect
                        dragStartRect = rect
                    } else {
                        cropRect = clampRect(cropRect, to: rect)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: onCancel)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .principal) {
                    Text("영역 선택")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("텍스트 추출") {
                        handleExtract()
                    }
                    .foregroundStyle(.yellow)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Overlay

    /// crop 영역만 비워둔 어두운 마스크.
    private func dimOverlay(containerSize: CGSize) -> some View {
        Rectangle()
            .fill(.black.opacity(0.55))
            .mask(
                Rectangle()
                    .overlay(
                        Rectangle()
                            .frame(width: cropRect.width, height: cropRect.height)
                            .position(x: cropRect.midX, y: cropRect.midY)
                            .blendMode(.destinationOut)
                    )
                    .compositingGroup()
            )
            .allowsHitTesting(false)
    }

    // MARK: - Crop frame + handles

    private var cropFrame: some View {
        ZStack {
            // 본체 — 안쪽 영역 드래그로 crop 이동
            Rectangle()
                .strokeBorder(Color.white, lineWidth: 2)
                .background(Color.clear.contentShape(Rectangle()))
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if dragStartRect == .zero || value.translation == .zero {
                                dragStartRect = cropRect
                            }
                            let newOrigin = CGPoint(
                                x: dragStartRect.origin.x + value.translation.width,
                                y: dragStartRect.origin.y + value.translation.height
                            )
                            cropRect = clampRect(
                                CGRect(origin: newOrigin, size: dragStartRect.size),
                                to: imageDisplayRect
                            )
                        }
                        .onEnded { _ in
                            dragStartRect = cropRect
                        }
                )

            // 3분할 격자선 (rule of thirds)
            gridLines

            // 4모서리 핸들
            cornerHandle(at: .topLeading)
            cornerHandle(at: .topTrailing)
            cornerHandle(at: .bottomLeading)
            cornerHandle(at: .bottomTrailing)
        }
    }

    private var gridLines: some View {
        Path { path in
            // 세로 2줄
            for i in 1...2 {
                let x = cropRect.minX + cropRect.width * CGFloat(i) / 3
                path.move(to: CGPoint(x: x, y: cropRect.minY))
                path.addLine(to: CGPoint(x: x, y: cropRect.maxY))
            }
            // 가로 2줄
            for i in 1...2 {
                let y = cropRect.minY + cropRect.height * CGFloat(i) / 3
                path.move(to: CGPoint(x: cropRect.minX, y: y))
                path.addLine(to: CGPoint(x: cropRect.maxX, y: y))
            }
        }
        .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
        .allowsHitTesting(false)
    }

    private enum Corner {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }

    private func cornerHandle(at corner: Corner) -> some View {
        let position = cornerPosition(corner)
        return Rectangle()
            .fill(Color.white)
            .frame(width: cornerVisualSize, height: cornerVisualSize)
            .overlay(
                Rectangle().stroke(Color.black.opacity(0.3), lineWidth: 0.5)
            )
            // hit area는 시각 크기보다 크게 확장 (cornerHandleSize)
            .frame(width: cornerHandleSize, height: cornerHandleSize)
            .contentShape(Rectangle())
            .position(x: position.x, y: position.y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartRect == .zero || value.translation == .zero {
                            dragStartRect = cropRect
                        }
                        cropRect = resizedRect(from: dragStartRect, corner: corner, translation: value.translation)
                    }
                    .onEnded { _ in
                        dragStartRect = cropRect
                    }
            )
    }

    private func cornerPosition(_ corner: Corner) -> CGPoint {
        switch corner {
        case .topLeading: CGPoint(x: cropRect.minX, y: cropRect.minY)
        case .topTrailing: CGPoint(x: cropRect.maxX, y: cropRect.minY)
        case .bottomLeading: CGPoint(x: cropRect.minX, y: cropRect.maxY)
        case .bottomTrailing: CGPoint(x: cropRect.maxX, y: cropRect.maxY)
        }
    }

    /// 특정 모서리를 잡고 드래그할 때 새 cropRect 계산.
    /// 최소 minCropSide, imageDisplayRect 경계 클램프 적용.
    private func resizedRect(from start: CGRect, corner: Corner, translation: CGSize) -> CGRect {
        var rect = start
        switch corner {
        case .topLeading:
            let newMinX = clamp(start.minX + translation.width, imageDisplayRect.minX, start.maxX - minCropSide)
            let newMinY = clamp(start.minY + translation.height, imageDisplayRect.minY, start.maxY - minCropSide)
            rect = CGRect(x: newMinX, y: newMinY, width: start.maxX - newMinX, height: start.maxY - newMinY)
        case .topTrailing:
            let newMaxX = clamp(start.maxX + translation.width, start.minX + minCropSide, imageDisplayRect.maxX)
            let newMinY = clamp(start.minY + translation.height, imageDisplayRect.minY, start.maxY - minCropSide)
            rect = CGRect(x: start.minX, y: newMinY, width: newMaxX - start.minX, height: start.maxY - newMinY)
        case .bottomLeading:
            let newMinX = clamp(start.minX + translation.width, imageDisplayRect.minX, start.maxX - minCropSide)
            let newMaxY = clamp(start.maxY + translation.height, start.minY + minCropSide, imageDisplayRect.maxY)
            rect = CGRect(x: newMinX, y: start.minY, width: start.maxX - newMinX, height: newMaxY - start.minY)
        case .bottomTrailing:
            let newMaxX = clamp(start.maxX + translation.width, start.minX + minCropSide, imageDisplayRect.maxX)
            let newMaxY = clamp(start.maxY + translation.height, start.minY + minCropSide, imageDisplayRect.maxY)
            rect = CGRect(x: start.minX, y: start.minY, width: newMaxX - start.minX, height: newMaxY - start.minY)
        }
        return rect
    }

    /// SwiftUI .scaledToFit()와 동일한 로직으로 이미지가 실제로 표시되는 CGRect를 계산.
    /// background GeometryReader onAppear 타이밍 이슈 없이 geometry.size 확정 시점에 호출된다.
    private func computeDisplayRect(in canvasSize: CGSize) -> CGRect {
        guard canvasSize.width > 0, canvasSize.height > 0,
              image.size.width > 0, image.size.height > 0 else { return .zero }
        let imageAspect = image.size.width / image.size.height
        let canvasAspect = canvasSize.width / canvasSize.height
        if imageAspect > canvasAspect {
            // 이미지가 더 넓음 → 폭에 맞춤, 위아래 레터박스
            let h = canvasSize.width / imageAspect
            return CGRect(x: 0, y: (canvasSize.height - h) / 2, width: canvasSize.width, height: h)
        } else {
            // 이미지가 더 좁음(세로) → 높이에 맞춤, 좌우 필러박스
            let w = canvasSize.height * imageAspect
            return CGRect(x: (canvasSize.width - w) / 2, y: 0, width: w, height: canvasSize.height)
        }
    }

    private func clampRect(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        guard bounds.width > 0 && bounds.height > 0 else { return rect }
        let width = min(rect.width, bounds.width)
        let height = min(rect.height, bounds.height)
        let x = clamp(rect.origin.x, bounds.minX, bounds.maxX - width)
        let y = clamp(rect.origin.y, bounds.minY, bounds.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
        min(max(value, lower), upper)
    }

    // MARK: - Extract

    /// 화면 좌표계 cropRect → 원본 이미지 좌표계 cropRect로 변환 후 crop된 UIImage 반환.
    /// 원본 해상도 유지 — OCR 정확도 최대화.
    private func handleExtract() {
        guard imageDisplayRect.width > 0, imageDisplayRect.height > 0 else {
            onExtract(image)
            return
        }
        guard let cgImage = image.cgImage else {
            onExtract(image)
            return
        }

        // image.size는 .imageOrientation에 따라 보정된 크기. CGImage 픽셀 차원은 .up 기준.
        // 단순화를 위해 image.size 기준으로 변환하고, 결과 UIImage에 원본 orientation 적용.
        let scaleX = image.size.width / imageDisplayRect.width
        let scaleY = image.size.height / imageDisplayRect.height

        let relativeX = (cropRect.minX - imageDisplayRect.minX) * scaleX
        let relativeY = (cropRect.minY - imageDisplayRect.minY) * scaleY
        let relativeW = cropRect.width * scaleX
        let relativeH = cropRect.height * scaleY

        // CGImage 좌표는 픽셀 단위 — image.scale 적용.
        let pixelRect = CGRect(
            x: relativeX * image.scale,
            y: relativeY * image.scale,
            width: relativeW * image.scale,
            height: relativeH * image.scale
        )

        // CGImage.cropping은 orientation을 고려하지 않으므로, orientation이 .up이 아닌 경우
        // 정상화된 UIImage를 먼저 만든 뒤 cropping.
        let normalizedImage: UIImage = image.imageOrientation == .up ? image : normalizedUpImage(image)
        guard let normalizedCG = normalizedImage.cgImage,
              let cropped = normalizedCG.cropping(to: pixelRect) else {
            onExtract(image)
            return
        }
        let croppedUIImage = UIImage(cgImage: cropped, scale: normalizedImage.scale, orientation: .up)
        onExtract(croppedUIImage)
    }

    /// EXIF orientation을 픽셀에 굽혀 .up orientation의 새 이미지를 생성.
    /// 큰 이미지에서 메모리 사용량이 일시적으로 늘지만 crop 후 즉시 폐기되므로 허용.
    private func normalizedUpImage(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
