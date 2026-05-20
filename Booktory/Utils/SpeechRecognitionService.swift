//
//  SpeechRecognitionService.swift
//  Booktory
//
//  AVAudioSession + SFSpeechRecognizer 기반 실시간 음성 → 텍스트 변환.
//
//  - 한국어(ko-KR) 인식.
//  - 침묵으로 세션이 자동 종료되면 즉시 재시작 (사용자가 완료 누를 때까지 연속 녹음).
//  - audio tap은 startRecording() 시 1회 설치. 세션 재시작 시 activeRequest 포인터만 교체.
//  - pauseRecording() / resumeRecording()으로 일시정지·재개 지원.
//    pause 시 audioEngine.pause() → tap·audio session 유지, resumeRecording()으로 재시작 가능.
//

import Foundation
import AVFoundation
import Speech
import Combine

enum RecordingState {
    case idle       // 한 번도 시작 안 한 상태
    case recording  // 적극적으로 녹음 중
    case paused     // 일시정지 (accumulated text 보존)
}

final class SpeechRecognitionService: ObservableObject {

    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var transcript: String = ""

    /// `state == .recording` 단축 프로퍼티 — beginSession 내부 조건 검사용.
    var isRecording: Bool { state == .recording }

    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// 침묵 자동 종료 전까지 누적된 확정 텍스트.
    private var accumulatedText: String = ""

    /// beginSession() 호출 시마다 증가.
    /// cancel → error 콜백 → beginSession() 무한 루프를 방지한다.
    private var currentSessionID: Int = 0

    // audio tap → recognition request 라우팅 (thread-safe).
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

    // MARK: - Recording lifecycle

    /// 처음 녹음 시작. tap 설치 + audio session 설정.
    func startRecording() throws {
        guard state == .idle else { return }
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

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.activeRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        state = .recording
        beginSession()
    }

    /// 녹음 일시정지. audio engine만 멈추고 tap·session은 유지.
    func pauseRecording() {
        guard state == .recording else { return }
        state = .paused
        currentSessionID += 1       // 진행 중인 인식 콜백 무시
        recognitionTask?.cancel()
        recognitionTask = nil
        activeRequest = nil
        audioEngine.pause()
    }

    /// 일시정지 후 재개. accumulated text 이어서 누적.
    func resumeRecording() throws {
        guard state == .paused else { return }
        try audioEngine.start()
        state = .recording
        beginSession()
    }

    /// 완전 종료 후 최종 transcript 반환.
    @discardableResult
    func stopRecording() -> String {
        state = .idle
        currentSessionID += 1
        activeRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return transcript
    }

    // MARK: - Session management

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

                if error != nil && self.isRecording {
                    self.beginSession()
                }
            }
        }
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
