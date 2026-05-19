//
//  OCRService.swift
//  Booktory
//
//  Apple Vision 기반 텍스트 추출 (OCR).
//  사진 기록 흐름에서 carry 이미지 → 문장 추출에 사용.
//
//  - 온디바이스 처리 (네트워크/API key 불필요)
//  - 한국어 + 영어 동시 인식 (Vision이 언어 분배)
//  - accurate 레벨로 정확도 우선 — 0.5~1.5s 예상
//

import Foundation
import UIKit
import Vision

enum OCRError: LocalizedError {
    case invalidImage
    case visionFailure(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "이미지를 처리할 수 없어요."
        case .visionFailure(let error):
            return "텍스트 인식 중 오류가 발생했어요: \(error.localizedDescription)"
        }
    }
}

enum OCRService {

    /// 이미지에서 텍스트를 추출한다. 인식 결과가 없으면 빈 문자열을 반환 (에러 아님).
    /// Vision 처리는 동기 호출이므로 백그라운드 큐에서 실행하고 결과는 main 스레드로 안전하게 돌려준다.
    static func extractText(
        from image: UIImage,
        languages: [String] = ["ko-KR", "en-US"]
    ) async throws -> String {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }
        let orientation = cgImageOrientation(from: image.imageOrientation)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            // Vision은 메인 스레드에서 perform하면 UI 멈춤 — userInitiated 큐로 dispatch.
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: OCRError.visionFailure(error))
                        return
                    }
                    let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                    let text = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                    continuation.resume(returning: text)
                }
                request.recognitionLevel = .accurate
                request.recognitionLanguages = languages
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.visionFailure(error))
                }
            }
        }
    }

    /// UIImage.Orientation → CGImagePropertyOrientation (Vision 입력용)
    private static func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
