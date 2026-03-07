# 11 — Live Activity (Dynamic Island / 잠금화면 타이머)

## 개요

독서 타이머가 실행 중일 때 Dynamic Island와 잠금화면에 실시간 경과 시간을 표시한다.
앱이 백그라운드로 가도 타이머 상태를 확인할 수 있어 독서 몰입을 돕는다.

현재 `BGTimer/` 폴더에 스텁(LiveActivityManager, LiveTimerWidget, TimerActivityAttributes)이 존재하며, 이를 완성한다.

**의존**: `04-timer-session`

> **Phase 3 기능** — MVP 이후 구현 예정

---

## 사용자 시나리오

1. 타이머 화면에서 독서 시작
2. 홈 버튼으로 앱을 백그라운드로
3. Dynamic Island에 책 제목 + 경과 시간 표시
4. 잠금화면에서도 타이머 확인 가능
5. Live Activity 탭 → 앱의 타이머 화면으로 복귀
6. 타이머 종료(나가기) 시 Live Activity 종료

---

## 기능 명세

### Live Activity 표시 정보
- 책 제목 (짧게 표시)
- 경과 시간 (타이머, `.timerInterval` 사용)
- 독서 중 상태 아이콘

### 업데이트 시점
- 타이머 시작 시: Live Activity 시작
- 일시정지 시: 표시를 "일시정지" 상태로 업데이트
- 재개 시: 타이머 재개
- 나가기(종료) 시: Live Activity 종료

### 플랫폼 지원
- Dynamic Island (iPhone 14 Pro 이상)
- 잠금화면 Live Activity 위젯 (iPhone 14 이상, iOS 16.2+)

---

## 데이터 구조

```swift
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var bookTitle: String
        var startTime: Date
        var isPaused: Bool
        var elapsedBeforePause: TimeInterval
    }
    var bookTitle: String
}
```

---

## 작업 목록

### 1. TimerActivityAttributes 완성
- [ ] `TimerActivityAttributes.swift` ContentState 정의
- [ ] `Info.plist`에 `NSSupportsLiveActivities: true` 추가

### 2. LiveTimerWidget 완성
- [ ] Dynamic Island compact 뷰 구현 (leading: 아이콘, trailing: 타이머)
- [ ] Dynamic Island expanded 뷰 구현 (책 제목 + 큰 타이머)
- [ ] 잠금화면 Live Activity 뷰 구현

### 3. LiveActivityManager 완성
- [ ] `start(bookTitle:startTime:)` — Activity 시작
- [ ] `pause(elapsed:)` — 일시정지 상태 업데이트
- [ ] `resume(newStartTime:)` — 재개 업데이트
- [ ] `stop()` — Activity 종료

### 4. 타이머와 연동
- [ ] `TimerView`/ViewModel의 시작/일시정지/재개/종료 시점에 `LiveActivityManager` 호출

---

## 완료 기준

- [ ] 타이머 시작 시 Dynamic Island에 타이머 표시됨
- [ ] 잠금화면에서 타이머가 실시간으로 증가함
- [ ] 일시정지 시 "일시정지" 상태로 표시 변경됨
- [ ] 타이머 종료 시 Live Activity가 사라짐
- [ ] Live Activity 탭 시 앱의 타이머 화면으로 이동함
