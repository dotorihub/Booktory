# 북토리 (Booktory) — 앱 기획 플랜

> 독서 기록 iOS 앱. 현재 읽고 있는 책을 관리하고, 독서 시간을 타이머로 측정하며, 읽은 기록을 쌓아가는 앱.

---

## 탭 구조

| 탭 | 이름 (안) | 핵심 역할 |
|---|---|---|
| 1 | 독서 | 읽고 있는 책 목록 + 타이머 진입 |
| 2 | 검색 | 책 검색 + 서재 추가 |
| 3 | 기록 | 독서 통계 + 달력 |
| 4 | 서재 | 내 책 목록 + 설정 |

> **탭 3 & 4 분리 이유**: "기록"은 시간/통계 중심이고, "서재"는 책 컬렉션+계정 관리 중심으로 성격이 달라 분리를 권장.

---

## 책 상태 흐름

```
[검색] → 읽고 싶은 → 읽고 있는 → 완독한
                         ↑
                   바로 읽기 (검색에서 직접 진입)
```

- **읽고 싶은**: 나중에 읽고 싶은 책 저장
- **읽고 있는**: 독서 탭에 노출, 타이머 사용 가능
- **완독한**: 독서 종료 처리 (세션 종료 시 수동 완독 처리)

---

## 탭별 기능 명세

---

### 탭 1 — 독서

#### 메인 화면
- 읽고 있는 책 리스트 (카드 형태)
  - 책 표지 / 제목 / 저자
  - 총 독서 시간 (누적)
  - [이어 읽기] 버튼
- **Empty State**: 읽고 있는 책이 없을 때
  - 안내 문구 + [책 검색하기] CTA → 탭 2로 이동

#### 타이머 화면 (fullScreenCover)
- 선택한 책 정보 표시
- 타이머 (시:분:초)
- 시작 / 일시정지 / 재개
- [나가기]: 타이머 중지 + 세션 누적 저장
- (Phase 3) 문장 기록 버튼 → 타이머 유지 + 문장 입력 화면 연결

---

### 탭 2 — 검색

#### 검색 화면
- 텍스트 필드 → Naver Books API 호출 (디바운싱 350ms)
- 검색 결과 리스트 (무한 스크롤, 20개씩 페이지네이션)
  - 책 표지 / 제목 / 저자 / 출판사
- Empty State / 로딩 / 에러 상태 처리

#### 책 상세 화면
- 책 표지 / 제목 / 저자 / 출판사 / 설명
- [바로 읽기] CTA
  - 서재에 "읽고 있는" 상태로 추가
  - 탭 1(독서)로 이동
  - 해당 책 타이머 자동 시작
- [읽고 싶은 책에 저장] CTA
  - 서재에 "읽고 싶은" 상태로 추가
  - 이미 저장된 경우 상태 표시 및 제거 토글

---

### 탭 3 — 기록

#### 통계 섹션
- 이번 주 총 독서 시간
- 전체 누적 독서 시간
- 완독한 책 권수
- (Phase 3) 기록한 문장 수

#### 달력 섹션
- **위클리 뷰** (기본): 최근 7일, 날짜별 독서 여부/시간 표시
- **먼슬리 뷰**: 월별 달력, 날짜 탭 시 해당 날의 독서 세션 상세
- 독서한 날 강조 표시 (색상 depth로 시간 표현 — GitHub 잔디 스타일 참고)

#### (Phase 3) 문장 기록 섹션
- 내가 기록한 문장/이미지 구절 리스트
- 책 제목 / 날짜 표시
- 문장 편집 / 삭제

---

### 탭 4 — 서재

#### 내 책 목록
- 탭 필터: **전체 / 읽고 있는 / 완독한 / 읽고 싶은**
- 책 카드 목록 (그리드 or 리스트 전환 가능)
- 카드 탭 → 책 상세/기록 상세 화면
  - 해당 책의 독서 세션 히스토리
  - 총 독서 시간
  - (Phase 3) 기록한 문장들

#### 설정 섹션
- 알림 설정 (독서 리마인더 등) — Phase 3
- 앱 테마 — Phase 3
- 데이터 백업/복원 — Phase 3
- 앱 정보 / 버전

---

## 데이터 모델

```swift
// 책 기본 정보 (API DTO에서 변환)
struct Book {
    var id: String          // ISBN
    var title: String
    var author: String
    var publisher: String
    var coverURL: String
    var description: String
}

// 내 서재의 책 (상태 포함)
@Model
class LibraryBook {
    var id: UUID
    var isbn: String
    var title: String
    var author: String
    var publisher: String
    var coverURL: String
    var bookDescription: String
    var status: ReadingStatus   // wantToRead | reading | completed
    var addedAt: Date
    var startedAt: Date?
    var completedAt: Date?

    @Relationship(deleteRule: .cascade)
    var sessions: [ReadingSession]
}

enum ReadingStatus: String, Codable {
    case wantToRead   // 읽고 싶은
    case reading      // 읽고 있는
    case completed    // 완독한
}

// 독서 세션 (타이머 1회 기록)
@Model
class ReadingSession {
    var id: UUID
    var libraryBookId: UUID     // LibraryBook 외래키
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval  // 초 단위

    @Relationship var libraryBook: LibraryBook?
}

// 문장/이미지 기록 (Phase 3)
// LibraryBook과 분리된 독립 모델, 외래키로 참조
@Model
class Quote {
    var id: UUID
    var libraryBookId: UUID     // LibraryBook 외래키
    var contentType: QuoteContentType
    var textContent: String?    // contentType == .text 일 때
    var imageData: Data?        // contentType == .image 일 때
    var createdAt: Date

    @Relationship var libraryBook: LibraryBook?
}

enum QuoteContentType: String, Codable {
    case text
    case image
}
```

> **Quote 설계 의도**: 문장(text)과 이미지(image) 등 다양한 콘텐츠 타입을 지원하기 위해 LibraryBook 내부 리스트가 아닌 독립 모델로 분리. `libraryBookId`로 외래키 참조. 추후 오디오, URL 등 타입 확장도 `QuoteContentType`에 케이스 추가로 대응 가능.

---

## 미결정 사항

| 항목 | 현재 상태 | 옵션 |
|---|---|---|
| 데이터 저장소 | 미정 | SwiftData (권장) / CoreData |
| 계정/동기화 | 미정 | 로컬 전용 vs iCloud 동기화 |
| 서재 카드 레이아웃 | 미정 | 그리드 / 리스트 / 전환 가능 |
| 완독 처리 방식 | 미정 | 세션 종료 시 팝업 제안 / 서재에서 수동 |

---

## 개발 로드맵

### Phase 1 — 핵심 루프 (MVP)

> 앱의 핵심 사용 흐름: 책 검색 → 서재 추가 → 타이머 독서 → 세션 저장

| 순서 | 작업 | 비고 |
|---|---|---|
| 1 | SwiftData 스키마 설정 (LibraryBook, ReadingSession) | 모든 기능의 기반 |
| 2 | LibraryRepository 구성 (CRUD) | ViewModel이 직접 ModelContext 접근하지 않도록 분리 |
| 3 | 탭 2 — 책 상세 화면 | 검색 결과 → 상세 |
| 4 | 탭 2 — 바로 읽기 / 읽고 싶은 책 저장 동작 | LibraryBook 상태 저장 |
| 5 | 탭 1 — 읽고 있는 책 목록 (Empty State 포함) | LibraryBook status == .reading 필터 |
| 6 | 탭 1 — 타이머 → 세션 저장 연동 | 나가기 시 ReadingSession 저장 |
| 7 | 탭 4 — 서재 목록 (탭 필터: 전체/읽고 있는/완독한/읽고 싶은) | |
| 8 | 탭 4 — 책 상세/세션 히스토리 화면 | |

### Phase 2 — 기록

> 쌓인 독서 데이터를 시각화

| 순서 | 작업 | 비고 |
|---|---|---|
| 9 | 탭 3 — 통계 수치 (이번 주 / 전체 시간 / 완독 권수) | ReadingSession 집계 |
| 10 | 탭 3 — 위클리 달력 | 기본 뷰 |
| 11 | 탭 3 — 먼슬리 달력 + 날짜별 세션 상세 | |

### Phase 3 — 심화

> 핵심 루프 완성 후 추가 가치 기능

| 순서 | 작업 | 비고 |
|---|---|---|
| 12 | Quote 모델 추가 및 타이머 화면 내 기록 진입 UI | 카메라/텍스트 버튼 |
| 13 | 탭 3 — 문장 기록 섹션 | Quote 리스트 |
| 14 | 탭 4 — 책 상세에서 문장 목록 연결 | |
| 15 | Live Activity (Dynamic Island / 잠금화면 타이머) | 스텁 완성 |
| 16 | 알림 / 설정 화면 | 리마인더 등 |
| 17 | iCloud 동기화 | 선택 사항 |

---

## 현재 구현 현황

| 기능 | 상태 |
|---|---|
| Naver Books API 검색 (디바운싱, 페이지네이션) | 완료 |
| 타이머 UI (시작/일시정지/재개, 백그라운드) | 완료 |
| 책 검색 결과 리스트 | 완료 |
| 탭 구조 (MainView 4탭) | 완료 |
| Live Activity 스캐폴딩 | 스텁 |
| SwiftData 스키마 / 데이터 저장 | 미구현 |
| 책 상세 화면 | 미구현 |
| 독서 탭 책 목록 | 미구현 |
| 기록/통계 탭 | 미구현 |
| 서재 탭 | 미구현 |
