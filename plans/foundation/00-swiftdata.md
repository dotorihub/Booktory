# 00 — SwiftData 스키마 + Repository 레이어

## 개요

모든 기능의 기반이 되는 데이터 레이어. SwiftData 모델 클래스를 정의하고, ViewModel이 데이터에 직접 접근하지 않도록 Repository 패턴으로 감싼다.
이 작업이 완료되어야 Phase 1의 모든 기능 개발이 가능하다.

---

## 모델 정의

### LibraryBook
```swift
@Model
class LibraryBook {
    var id: UUID
    var isbn: String
    var title: String
    var author: String
    var publisher: String
    var coverURL: String
    var bookDescription: String
    var status: ReadingStatus
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
```

### ReadingSession
```swift
@Model
class ReadingSession {
    var id: UUID
    var libraryBookId: UUID
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval   // 초 단위

    @Relationship var libraryBook: LibraryBook?
}
```

---

## Repository 인터페이스

```swift
protocol LibraryRepositoryProtocol {
    // 조회
    func fetchAll() throws -> [LibraryBook]
    func fetchBy(status: ReadingStatus) throws -> [LibraryBook]
    func fetchBy(isbn: String) throws -> LibraryBook?

    // 추가 / 수정
    func add(book: LibraryBook) throws
    func updateStatus(id: UUID, status: ReadingStatus) throws
    func delete(id: UUID) throws

    // 세션
    func addSession(_ session: ReadingSession, to bookId: UUID) throws
    func fetchSessions(for bookId: UUID) throws -> [ReadingSession]
}
```

---

## 작업 목록

### 1. 프로젝트 SwiftData 설정
- [ ] `BooktoryApp.swift`에 `.modelContainer(for:)` 추가
- [ ] `LibraryBook.swift` 파일 생성 및 `@Model` 클래스 작성
- [ ] `ReadingStatus` enum 정의 (Codable, RawRepresentable)
- [ ] `ReadingSession.swift` 파일 생성 및 `@Model` 클래스 작성
- [ ] `@Relationship` 연결 확인 (LibraryBook ↔ ReadingSession)

### 2. Repository 구현
- [ ] `LibraryRepositoryProtocol` 프로토콜 파일 생성
- [ ] `DefaultLibraryRepository` 구현체 작성
  - [ ] `fetchAll()` — 전체 조회
  - [ ] `fetchBy(status:)` — 상태별 필터 조회
  - [ ] `fetchBy(isbn:)` — ISBN으로 존재 여부 확인
  - [ ] `add(book:)` — 서재에 추가
  - [ ] `updateStatus(id:status:)` — 상태 변경
  - [ ] `delete(id:)` — 삭제
  - [ ] `addSession(_:to:)` — 세션 저장
  - [ ] `fetchSessions(for:)` — 책별 세션 조회

### 3. 유틸리티
- [ ] `ReadingSession`에 `totalDuration(sessions:)` 집계 헬퍼 작성
  - 세션 배열 → 총 초 → "X시간 Y분" 포맷 변환
- [ ] `LibraryBook`에서 `Book` (Naver API 모델) 변환 이니셜라이저 작성

### 4. 검증
- [ ] SwiftUI Preview 환경에서 in-memory container 동작 확인
- [ ] Xcode 시뮬레이터에서 데이터 생성/조회/삭제 흐름 수동 확인

---

## 파일 구조

```
Booktory/
└── Data/
    ├── Model/
    │   ├── LibraryBook.swift
    │   └── ReadingSession.swift
    └── Repository/
        ├── LibraryRepositoryProtocol.swift
        └── DefaultLibraryRepository.swift
```

---

## 완료 기준

- [ ] 앱 실행 시 SwiftData 컨테이너 오류 없이 초기화됨
- [ ] `LibraryBook` CRUD가 영속적으로 저장됨 (앱 재시작 후에도 유지)
- [ ] `ReadingSession` 추가 시 `LibraryBook.sessions`에 반영됨
- [ ] Preview 환경에서 in-memory 컨테이너로 정상 동작함
