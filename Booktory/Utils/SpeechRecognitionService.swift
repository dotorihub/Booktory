//
//  SpeechRecognitionService.swift
//  Booktory
//
//  AVAudioSession + SFSpeechRecognizer 기반 실시간 음성 → 텍스트 변환.
//
//  - 온디바이스 처리 우선 (requiresOnDeviceRecognition 옵션)
//  - 한국어(ko-KR) 인식. 침묵으로 세션이 자동 종료되면 즉시 재시작해 사용자가
//    [완료]를 누를 때까지 연속 녹음을 유지한다.
//  - audio tap은 녹음 시작 시 1회 설치, 세션 재시작 시 교체하지 않고
//    activeRequest 포인터만 바꿔 새 세션으로 라우팅한다.
//

import Foundation
import AVFoundation
import Speech
import Combine

final class SpeechRecognitionService: ObservableObject {

    @Published private(set) var transcript: String = ""
    @Published private(set) var isRecording: Bool = false

    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// 침묵 자동 종료 전까지 누적된 확정 텍스트.
    private var accumulatedText: String = ""

    /// beginSession() 호출 시마다 증가. cancel로 인한 오래된 콜백을 무시하기 위해 사용.
    /// cancel → error 콜백 → 다시 beginSession() 무한루프를 방지한다.
    private var currentSessionID: Int = 0

    // Audio tap → recognition request 라우팅을 thread-safe하게 관리.
    private let requestLock = NSLock()
    private var _activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest? {
        get { requestLock.withLock { _activeRequest } }
        set { requestLock.withLock { _activeRequest = newValue } }
    }

    // MARK: - Permissions

    static func requestPermissions() async -> Bool {
        let speechGranted = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else { return false }
        return await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    static var currentStatus: (speech: SFSpeechRecognizerAuthorizationStatus,
                                mic: AVAudioSession.RecordPermission) {
        (SFSpeechRecognizer.authorizationStatus(), AVAudioSession.sharedInstance().recordPermission)
    }

    // MARK: - Recording

    func startRecording() throws {
        guard !isRecording else { return }
        accumulatedText = ""
        transcript = ""

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR")),
              recognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }
        self.recognizer = recognizer

        // tap은 전체 녹음 세션 동안 1회만 설치 — 세션 재시작 시 activeRequest만 교체.
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.activeRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        beginSession()
    }

    /// 침묵 감지로 자동 종료된 인식 세션을 재시작.
    /// audio engine은 그대로 유지하고 request/task만 새로 생성한다.
    private func beginSession() {
        recognitionTask?.cancel()
        recognitionTask = nil
        currentSessionID += 1
        let sessionID = currentSessionID

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        activeRequest = request

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            DispatchQueue.main.async {
                // cancel()로 인한 오래된 콜백 무시 — 무한 루프 방지
                guard self.currentSessionID == sessionID else { return }

                if let result {
                    let segment = result.bestTranscription.formattedString
                    self.transcript = [self.accumulatedText, segment]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")

                    if result.isFinal && self.isRecording {
                        let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            self.accumulatedText = self.transcript
                        }
                        self.beginSession()
                    }
                }

                // 에러(침묵 타임아웃 포함) → 누적 보존 후 재시작
                if error != nil && self.isRecording {
                    self.beginSession()
                }
            }
        }
    }

    /// 녹음 중지 후 최종 transcript 반환.
    @discardableResult
    func stopRecording() -> String {
        isRecording = false
        activeRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return transcript
    }
}

enum SpeechError: LocalizedError {
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "음성 인식을 현재 사용할 수 없어요. 잠시 후 다시 시도해주세요."
        }
    }
}
