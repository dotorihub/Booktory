# SRS — 타이머 ↔ 세션 저장 연동

> Phase 1 — `05-timer-session` 구현 기술 명세

---

## 1. 개요

기존 `TimerView`는 경과 시간을 UI로만 표시하고, 종료 시 아무 데이터도 저장하지 않는다.
이 작업에서 타이머 종료(나가기) 시 `ReadingSession`을 생성하여 SwiftData에 저장하고,
독서 탭 카드의 누적 시간에 즉시 반영되도록 연동한다.

**의존**: `srs/data-layer.md`, `srs/reading-tab.md`

**핵심 변경**: `TimerView`(View) → `TimerViewModel`(ViewModel) 분리 + 세션 저장 로직 추가

---

## 2. 컴포넌트 구조

```
TimerView (View)
├── 책 표지 / 제목 / 저자
├── 타이머 디스플레이 (HH:mm:ss)
├── 시작 / 일시정지 / 재개 버튼
└── 나가기 버튼 (xmark)
        │
        └── onDismiss 시 세션 저장
                │
                ▼
TimerViewModel (@MainActor ObservableObject)
├── 타이머 상태 관리 (running / paused)
├── 경과 시간 계산
├── 세션 저장 (Repository 호출)
└── 나가기 확인 Alert 트리거
```

---

## 3. ViewModel 설계

### `TimerViewModel`

기존 `TimerView` 내부의 `@State` 기반 타이머 로직을 ViewModel로 추출한다.

```swift
@MainActor
final class TimerViewModel: ObservableObject {

    // MARK: - 상태

    enum TimerState {
        case idle       // 초기 상태 (진입 직후, 아직 시작 전)
        case running    // 타이머 진행 중
        case paused     // 일시정지
    }

    @Published private(set) var timerState: TimerState = .idle
    @Published private(set) var elapsed: TimeInterval = 0

    /// 나가기 확인 Alert 트리거
    @Published var showExitConfirm: Bool = false

    let book: LibraryBook

    // MARK: - 내부 상태

    /// 세션 전체의 시작 시각 (타이머 최초 시작 시 기록, 세션 저장에 사용)
    private var sessionStartTime: Date?

    /// 현재 진행 구간의 시작 시각 (resume마다 갱신)
    private var currentRunStartDate: Date?

    /// 일시정지 전까지의 누적 시간
    private var elapsedBeforePause: TimeInterval = 0

    private let repository: any LibraryRepositoryProtocol
    private let logger = Logger(subsystem: "com.booktory", category: "Timer")

    private let minimumSessionDuration: TimeInterval = 60  // 1분

    init(book: LibraryBook, repository: any LibraryRepositoryProtocol) {
        self.book = book
        self.repository = repository
    }
}
```

### 공개 인터페이스

```swift
extension TimerViewModel {

    /// 타이머 시작 (최초 진입 시 자동 호출)
    func start() {
        sessionStartTime = Date()
        currentRunStartDate = Date()
        timerState = .running
    }

    /// 일시정지
    func pause() {
        guard timerState == .running, let runStart = currentRunStartDate else { return }
        elapsedBeforePause += Date().timeIntervalSince(runStart)
        currentRunStartDate = nil
        timerState = .paused
    }

    /// 재개
    func resume() {
        currentRunStartDate = Date()
        timerState = .running
    }

    /// Timer.publish의 매 틱마다 호출
    func tick() {
        guard timerState == .running, let runStart = currentRunStartDate else { return }
        elapsed = elapsedBeforePause + Date().timeIntervalSince(runStart)
    }

    /// 나가기 버튼 탭 시 호출
    /// - 타이머가 idle(시작 전)이면 바로 dismiss
    /// - 타이머가 running/paused이면 확인 Alert 표시
    func requestExit() -> Bool {
        if timerState == .idle {
            return true  // 바로 dismiss 가능
        }
        // running 상태면 먼저 일시정지
        if timerState == .running {
            pause()
        }
        showExitConfirm = true
        return false  // Alert로 확인 후 dismiss
    }

    /// 확인 Alert에서 [종료] 선택 시 호출
    /// 세션을 저장하고 dismiss 가능 상태를 반환한다.
    func confirmExit() {
        saveSessionIfNeeded()
    }

    /// 확인 Alert에서 [계속 읽기] 선택 시 호출
    func cancelExit() {
        // 일시정지 상태 유지 — 사용자가 수동으로 재개
    }
}
```

### 세션 저장 로직

```swift
private extension TimerViewModel {

    /// 세션 저장 조건: 누적 독서 시간 ≥ 1분
    func saveSessionIfNeeded() {
        let duration = elapsed
        guard duration >= minimumSessionDuration else {
            logger.info("독서 시간 \(Int(duration))초 — 최소 기준(60초) 미달, 세션 저장 생략")
            return
        }

        guard let startTime = sessionStartTime else {
            logger.warning("sessionStartTime이 nil — 세션 저장 불가")
            return
        }

        let session = ReadingSession(
            libraryBookId: book.id,
            startTime: startTime,
            endTime: Date(),
            duration: duration
        )

        do {
            try repository.addSession(session, to: book.id)
            logger.info("세션 저장 완료: \(Int(duration))초")
        } catch {
            // PRD: 저장 실패 시 에러 로그만 기록, UI 에러 표시 안 함
            logger.error("세션 저장 실패: \(error.localizedDescription)")
        }
    }
}
```

---

## 4. View 변경

### `TimerView` 리팩토링

기존 `@State` 기반 로직을 `TimerViewModel`로 교체한다.

```swift
struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(book: LibraryBook, repository: any LibraryRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: TimerViewModel(
            book: book,
            repository: repository
        ))
    }

    var body: some View {
        VStack(spacing: 40) {
            // 나가기 버튼
            exitButton

            // 책 정보 (표지, 제목, 저자) — 기존 유지
            bookInfoSection

            Spacer()

            // 타이머 + 제어 버튼
            timerSection
        }
        .onAppear { viewModel.start() }
        .onReceive(timer) { _ in viewModel.tick() }
        .alert("독서를 종료할까요?", isPresented: $viewModel.showExitConfirm) {
            Button("계속 읽기", role: .cancel) { viewModel.cancelExit() }
            Button("종료하기") {
                viewModel.confirmExit()
                dismiss()
            }
        } message: {
            let minutes = Int(viewModel.elapsed) / 60
            if minutes >= 1 {
                Text("\(minutes)분 동안 읽었어요. 종료하면 독서 기록이 저장됩니다.")
            } else {
                Text("1분 미만의 독서는 기록되지 않습니다.")
            }
        }
    }
}
```

### 나가기 버튼 동작

```swift
private var exitButton: some View {
    HStack {
        Spacer()
        Button {
            if viewModel.requestExit() {
                dismiss()
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.15))
                .clipShape(Circle())
        }
        .accessibilityLabel("나가기")
    }
    .padding(.horizontal, 20)
}
```

### 타이머 제어 버튼 상태

```swift
private var timerSection: some View {
    VStack(spacing: 20) {
        Text(viewModel.formattedElapsed)
            .font(.system(size: 44, weight: .bold, design: .monospaced))

        switch viewModel.timerState {
        case .idle:
            // start()가 onAppear에서 호출되므로 일반적으로 노출되지 않음
            EmptyView()
        case .running:
            pauseButton
        case .paused:
            resumeButton
        }
    }
}
```

---

## 5. ReadingTabView 연동

### Repository 전달

`ReadingTabContentView`에서 `TimerView`에 repository를 전달한다.

```swift
// 변경 전
.fullScreenCover(item: $viewModel.selectedBook, onDismiss: {
    Task { await viewModel.loadBooks() }
}) { book in
    TimerView(book: book)
}

// 변경 후
.fullScreenCover(item: $viewModel.selectedBook, onDismiss: {
    Task { await viewModel.loadBooks() }
}) { book in
    TimerView(book: book, repository: repository)
}
```

`onDismiss`에서 `loadBooks()`가 호출되므로, 세션 저장 후 누적 시간이 자동으로 갱신된다.

---

## 6. 포맷팅 헬퍼

`TimerViewModel`에 포맷 메서드를 추가한다.

```swift
extension TimerViewModel {
    /// "00:23:41" 형식
    var formattedElapsed: String {
        let total = Int(elapsed)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
```

---

## 7. 엣지 케이스

| 상황 | 처리 |
|---|---|
| 1분 미만 독서 후 나가기 | 세션 저장하지 않음, Alert에 "1분 미만의 독서는 기록되지 않습니다" 표시 |
| 일시정지 중 나가기 | 일시정지까지의 누적 시간으로 세션 저장 |
| 백그라운드 진입 후 복귀 | `Timer.publish`는 백그라운드에서 멈추지만, `Date()` 기반 계산이므로 복귀 시 정확한 경과 시간 반영 |
| 세션 저장 실패 (DB 에러) | Logger로 에러 기록, UI에 에러 표시 안 함, 정상 dismiss |
| 같은 책으로 여러 번 진입/종료 | 매번 별도 `ReadingSession` 생성 |

---

## 8. 작업 목록

### 1. TimerViewModel 생성
- [ ] `TimerViewModel.swift` 생성 (`@MainActor ObservableObject`)
- [ ] `TimerState` enum 정의 (idle / running / paused)
- [ ] 기존 `TimerView`의 `@State` 타이머 로직 이관 (start, pause, resume, tick)
- [ ] `sessionStartTime` 기록 (세션 시작 시각)
- [ ] `formattedElapsed` 포맷팅 프로퍼티

### 2. 세션 저장 로직
- [ ] `saveSessionIfNeeded()` — 1분 이상이면 `ReadingSession` 생성 및 `addSession` 호출
- [ ] 저장 실패 시 Logger로 에러 기록

### 3. 나가기 플로우
- [ ] `requestExit()` — running이면 일시정지 후 확인 Alert 트리거
- [ ] `confirmExit()` — 세션 저장 후 dismiss
- [ ] `cancelExit()` — 일시정지 상태 유지
- [ ] 확인 Alert UI (독서 시간 표시, 1분 미만 안내)

### 4. TimerView 리팩토링
- [ ] `@State` 기반 로직 제거, `@StateObject TimerViewModel` 사용
- [ ] `init(book:repository:)` — repository 주입
- [ ] `onAppear`에서 `viewModel.start()` 호출
- [ ] `onReceive(timer)`에서 `viewModel.tick()` 호출
- [ ] 나가기 버튼에 `viewModel.requestExit()` 연결
- [ ] 확인 Alert 바인딩

### 5. ReadingTabView 연동
- [ ] `TimerView` 생성 시 repository 전달
- [ ] `onDismiss`에서 `loadBooks()` 호출 (기존 유지)

---

## 9. 완료 기준

- [ ] 타이머 종료(나가기) 시 `ReadingSession`이 SwiftData에 저장됨
- [ ] 1분 미만 독서는 세션이 저장되지 않음
- [ ] 나가기 시 확인 Alert 표시 ("독서를 종료할까요?")
- [ ] 세션 저장 후 독서 탭 카드의 누적 시간이 업데이트됨
- [ ] 일시정지 중 나가도 일시정지까지의 시간으로 세션 저장됨
- [ ] 동일 책으로 여러 세션 저장이 정상 동작함
- [ ] 기존 `TimerView`의 `@State` 로직이 `TimerViewModel`로 분리됨
