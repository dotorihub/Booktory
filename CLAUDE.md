# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Role

You are a **senior iOS developer**. Write production-quality Swift/SwiftUI code that is clean, testable, and maintainable.

---

## Project Overview

**북토리 (Booktory)** — 독서 기록 iOS 앱 (SwiftUI)
- Naver Books Open API로 책 검색
- 독서 타이머 (백그라운드 지원, 향후 Live Activity 연동)
- SwiftData 기반 로컬 서재 / 독서 세션 저장
- 4탭 구조: 독서 탭 / 검색 탭 / 기록 탭 / 서재 탭

기획 문서: `plan.md` (전체 기능 명세)
PRD: `plans/` 폴더 (기능별 세부 명세)
SRS: `srs/data-layer.md` (데이터 레이어 기술 명세)

---

## Building & Running

Xcode 프로젝트. CLI 빌드 없음. `Booktory.xcodeproj` 열고 ⌘R.

- **최소 배포 타겟**: iOS 17+ (SwiftData 필수)
- **API 인증**: `Booktory/Configs/Secrets.xcconfig` (gitignored)
  - `API_CLIENT_ID`, `API_CLIENT_SECRET` 필요
  - `Info.plist` → `AppConfig`를 통해 런타임에 읽음

---

## Architecture

### 패턴: MVVM

```
View  ──(바인딩)──▶  ViewModel  ──▶  Repository / Service
 │                      │
 │                   비즈니스 로직
 │                   상태 관리
 └── UI 렌더링만 담당
```

- **View**: UI 렌더링과 사용자 입력만 담당. 비즈니스 로직 작성 금지.
- **ViewModel**: `@MainActor ObservableObject`. 상태 관리, 비즈니스 로직, Repository/Service 호출.
- **Repository**: 데이터 접근 추상화. ViewModel이 SwiftData `ModelContext`에 직접 접근하지 않음.
- **Service**: 네트워크 호출 추상화 (`BookSearchService` 등).

### 탭 구조 (`MainView`)

| 탭 인덱스 | 뷰 | 역할 |
|---|---|---|
| 0 | `TimerMainView` (→ 독서 탭으로 전환 예정) | 읽고 있는 책 목록 + 타이머 |
| 1 | `SearchView` | 책 검색 |
| 2 | `RecordView` (미구현) | 기록 / 통계 / 달력 |
| 3 | `LibraryView` (미구현) | 서재 / 설정 |

### 폴더 구조

```
Booktory/
├── Configs/
│   └── AppConfig.swift           ← API 키 등 환경 설정
├── Data/                         ← (신규) 데이터 레이어
│   ├── Model/
│   │   ├── LibraryBook.swift
│   │   └── ReadingSession.swift
│   └── Repository/
│       ├── LibraryRepositoryProtocol.swift
│       └── DefaultLibraryRepository.swift
├── Networking/                   ← 네트워크 레이어
│   ├── NetworkClient.swift
│   ├── APIEndpoint.swift
│   ├── APIError.swift
│   ├── HTTPMethod.swift
│   ├── Model/BookModels.swift
│   └── Service/BookSearchService.swift
├── UI/
│   ├── Main/MainView.swift
│   ├── Search/
│   │   ├── SearchView.swift
│   │   └── SearchViewModel.swift
│   ├── Timer/
│   │   ├── TimerView.swift
│   │   ├── TimerMainView.swift
│   │   └── BGTimer/              ← Live Activity 스텁
│   ├── Reading/                  ← (신규) 독서 탭
│   ├── Library/                  ← (신규) 서재 탭
│   └── Record/                   ← (신규) 기록 탭
└── Resources/
    └── Color/Color+.swift
```

### 네트워킹 레이어

| 파일 | 역할 |
|---|---|
| `NetworkClient.swift` | Protocol + `DefaultNetworkClient` (`URLSession` 래핑) |
| `APIEndpoint.swift` | `URLRequest` 빌더 (path / method / headers / query) |
| `APIError.swift` | `LocalizedError` enum |
| `BookSearchService.swift` | Naver Books `/v1/search/book.json` 호출 |
| `BookModels.swift` | `NaverBookItem` (DTO) → `Book` (앱 모델, HTML 태그 제거) |

### 검색 (`UI/Search/`)

- **`SearchViewModel`** (`@MainActor ObservableObject`): 상태 머신 (`idle | loading | loaded([Book]) | failed(String)`), 350ms 디바운싱, 20개 페이지네이션
- **`SearchView`**: `@ViewBuilder content`로 상태 렌더링, `LazyVStack` + `onAppear` 무한 스크롤

### 타이머 (`UI/Timer/`)

- **`TimerView`**: fullScreen 독서 타이머. `Timer.publish` 1초 틱. 경과 시간 = `elapsedBeforePause + Date().timeIntervalSince(startDate)`
- **`TimerMainView`**: 타이머 진입 허브. `.fullScreenCover`로 `TimerView` 표시. `@Binding var selectedTab`으로 탭 전환.
- **`BGTimer/`**: Live Activity 스캐폴딩 (현재 스텁)

---

## 개발 규칙

### Swift / SwiftUI

- Swift 5.9+, SwiftUI, `async/await` 사용
- `@MainActor`를 ViewModel에 명시적으로 붙임
- 프로토콜 기반 설계: 구현체보다 프로토콜에 의존 (DI 가능하도록)
- `enum`으로 상태 표현 (Bool 플래그 남발 금지)
- 옵셔널 강제 언래핑(`!`) 사용 금지. `guard let` / `if let` / `??` 사용
- `Magic number` 사용 금지. 상수 또는 enum으로 정의

### MVVM 규칙

- View에 비즈니스 로직 작성 금지. 조건 분기가 필요하면 ViewModel로 이동
- ViewModel은 View를 import하지 않음
- ViewModel 프로퍼티는 최소한만 `@Published`로 노출
- 복잡한 ViewModel은 UseCase / Repository로 책임 분리

### 데이터 레이어

- ViewModel은 `LibraryRepositoryProtocol`을 통해서만 데이터 접근
- `ModelContext` 직접 접근은 Repository 내부에서만 허용
- 자세한 계약은 `srs/data-layer.md` 참고

### 에러 처리

- 네트워크/DB 오류는 반드시 처리. 무시하지 않음
- 사용자에게 노출할 에러는 한국어 메시지로
- `do-catch`에서 `catch { _ in }` 금지. 에러 타입을 명시적으로 처리
- 치명적이지 않은 에러는 `Logger` (OSLog)로 기록

### 테스트

- ViewModel은 단위 테스트 작성
- Repository는 프로토콜 기반으로 Mock 교체 가능하게 설계
- Preview는 in-memory SwiftData 컨테이너 사용 (`ModelConfiguration(isStoredInMemoryOnly: true)`)
- 테스트 타겟: `BooktoryTests/`

### 코드 스타일

- 파일당 하나의 주요 타입
- 재사용 가능한 UI 컴포넌트는 `UI/Components/`에 분리
- SwiftUI Preview는 모든 View에 작성
- 주석은 "무엇"이 아닌 "왜"를 설명. 자명한 코드에 주석 금지

### 접근성 / 한국어

- 사용자에게 표시되는 모든 문자열은 한국어
- SF Symbols 사용 시 `accessibilityLabel` 제공

---

## 현재 구현 현황

| 기능 | 상태 |
|---|---|
| Naver Books API 검색 (디바운싱, 페이지네이션) | 완료 |
| 타이머 UI (시작/일시정지/재개) | 완료 |
| 탭 구조 (MainView) | 완료 |
| Live Activity 스캐폴딩 | 스텁 |
| SwiftData 데이터 레이어 | **다음 작업** |
| 책 상세 화면 | 미구현 |
| 독서 탭 | 미구현 |
| 기록 탭 | 미구현 |
| 서재 탭 | 미구현 |
