# 12 — 알림 + 설정 화면

## 개요

서재 탭 하단의 설정 섹션. 독서 리마인더 알림 설정과 앱 기본 정보를 제공한다.

**의존**: `05-library-tab`

> **Phase 3 기능** — MVP 이후 구현 예정

---

## 사용자 시나리오

1. 서재 탭 하단 설정 섹션 접근 (또는 별도 설정 화면 push)
2. 독서 리마인더 알림 ON/OFF
3. 알림 시간 설정 (예: 매일 오후 9시)
4. 앱 버전 정보 확인

---

## 기능 명세

### 알림 설정
- 독서 리마인더 ON/OFF 토글
- ON 시 알림 시간 선택 (DatePicker, 시/분)
- 매일 반복 알림 (`UNUserNotificationCenter`)
- 알림 권한 미허용 시 설정 앱으로 유도

### 앱 정보
- 버전 정보 (`Bundle.main.infoDictionary["CFBundleShortVersionString"]`)
- 오픈소스 라이선스 (선택)

---

## 작업 목록

### 1. 알림 권한 요청
- [ ] 앱 첫 실행 또는 설정 진입 시 `UNUserNotificationCenter` 권한 요청
- [ ] 권한 거부 시 설정 앱 유도 Alert

### 2. 알림 스케줄 관리
- [ ] `NotificationManager` 작성
  - [ ] `scheduleDaily(at:)` — 매일 특정 시간 알림 등록
  - [ ] `cancelAll()` — 알림 전체 취소

### 3. 설정 화면 UI
- [ ] `SettingsView.swift` 생성
- [ ] 리마인더 토글 + 시간 선택 `DatePicker`
- [ ] 앱 버전 표시
- [ ] `UserDefaults`에 설정값 저장

### 4. 서재 탭 연동
- [ ] `LibraryTabView` 하단에 설정 진입 버튼 또는 섹션 추가

---

## 완료 기준

- [ ] 알림 권한 요청 플로우가 동작함
- [ ] 리마인더 ON 설정 시 지정 시간에 알림이 수신됨
- [ ] 리마인더 OFF 시 예약된 알림이 취소됨
- [ ] 앱 재시작 후에도 알림 설정이 유지됨
- [ ] 앱 버전이 설정 화면에 표시됨
