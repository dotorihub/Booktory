# SRS — 데이터 레이어

## 1. 개요

북토리 앱의 데이터는 두 가지 출처로 나뉜다.

| 출처 | 역할 | 저장 여부 |
|---|---|---|
| Naver Books API | 책 검색 결과 (메타데이터) | 저장 안 함 |
| SwiftData (로컬 DB) | 사용자 서재 / 독서 세션 | 영구 저장 |

API는 검색할 때마다 호출되며 결과를 임시로 뷰에 표시하는 용도다.
사용자가 "서재에 추가"하는 순간 API 결과물을 `LibraryBook`으로 변환해 로컬에 저장한다.
이후 서재, 독서 탭, 기록 탭의 모든 데이터는 로컬 DB에서만 읽는다.

---

## 2. 데이터 흐름

```
[Naver Books API]
      │
      │  NaverBookItem (DTO)
      ▼
[BookSearchService]  ──변환──▶  Book (앱 내 검색 모델)
                                   │
                         사용자가 "서재에 추가" / "바로 읽기"
                                   │
                                   ▼
                            LibraryBook (SwiftData)
                            ┌──────────────────────┐
                            │ isbn, title, author  │
                            │ coverURL, status     │
                            │ addedAt, startedAt   │
                            └──────────┬───────────┘
                                       │ 1 : N
                                       ▼
                              ReadingSession (SwiftData)
                              ┌────────────────────┐
                              │ startTime, endTime │
                              │ duration           │
                              └────────────────────┘
```

---

## 3. SwiftData 스키마

### 3-1. LibraryBook

사용자의 서재에 등록된 책 하나를 나타낸다.

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | `UUID` | 앱 내 고유 식별자 (PK) |
| `isbn` | `String` | Naver API의 ISBN (중복 추가 방지용) |
| `title` | `String` | 책 제목 |
| `author` | `String` | 저자 |
| `publisher` | `String` | 출판사 |
| `coverURL` | `String` | 표지 이미지 URL |
| `bookDescription` | `String` | 책 소개 |
| `status` | `ReadingStatus` | 현재 상태 (아래 참조) |
| `addedAt` | `Date` | 서재에 추가된 시각 |
| `startedAt` | `Date?` | 처음 읽기 시작한 시각 |
| `completedAt` | `Date?` | 완독 처리된 시각 |
| `sessions` | `[ReadingSession]` | 연결된 독서 세션 목록 (1:N) |

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
```

> `deleteRule: .cascade` — LibraryBook 삭제 시 연결된 모든 ReadingSession도 함께 삭제된다.

---

### 3-2. ReadingSession

타이머 1회 실행 기록. 사용자가 [이어 읽기]를 누르고 [나가기]를 누를 때마다 1개 생성된다.

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | `UUID` | 고유 식별자 (PK) |
| `libraryBookId` | `UUID` | 연결된 LibraryBook의 id (FK) |
| `startTime` | `Date` | 타이머 시작 시각 |
| `endTime` | `Date` | 타이머 종료 시각 |
| `duration` | `TimeInterval` | 실제 독서 시간 (초 단위, 일시정지 제외) |

```swift
@Model
class ReadingSession {
    var id: UUID
    var libraryBookId: UUID
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval  // 초 단위

    @Relationship var libraryBook: LibraryBook?
}
```

> `duration`은 `endTime - startTime`이 아니다.
> 일시정지 구간을 제외한 **실제 읽은 시간**이며, 타이머 종료 시점의 경과 시간을 그대로 저장한다.

---

### 3-3. ReadingStatus

`LibraryBook`의 상태를 나타내는 열거형.

```swift
enum ReadingStatus: String, Codable {
    case wantToRead   // 읽고 싶은
    case reading      // 읽고 있는
    case completed    // 완독한
}
```

**상태 전이 규칙:**

```
[검색 결과]
    │
    ├─ "바로 읽기"         →  reading
    └─ "읽고 싶은 책 저장"  →  wantToRead
                                  │
                             "바로 읽기"
                                  │
                                  ▼
                              reading
                                  │
                          "완독으로 표시"
                                  │
                                  ▼
                             completed
```

- `wantToRead` → `reading`: 바로 읽기 액션 또는 서재 상세에서 "읽기 시작"
- `reading` → `completed`: 서재 상세에서 "완독으로 표시"
- 역방향 전이는 현재 스코프에서 지원하지 않음

---

## 4. Repository 인터페이스

ViewModel이 SwiftData `ModelContext`에 직접 접근하지 않도록 Repository 레이어로 감싼다.
이 인터페이스를 통해서만 데이터를 읽고 쓴다.

```swift
protocol LibraryRepositoryProtocol {

    // MARK: - LibraryBook 조회
    func fetchAll() throws -> [LibraryBook]
    func fetchBy(status: ReadingStatus) throws -> [LibraryBook]
    func fetchBy(isbn: String) throws -> LibraryBook?   // nil이면 서재에 없음

    // MARK: - LibraryBook 쓰기
    func add(_ book: LibraryBook) throws
    func updateStatus(id: UUID, to status: ReadingStatus) throws
    func delete(id: UUID) throws

    // MARK: - ReadingSession
    func addSession(_ session: ReadingSession, to bookId: UUID) throws
    func fetchSessions(for bookId: UUID) throws -> [ReadingSession]
}
```

### 각 메서드 계약

| 메서드 | 입력 | 출력 | 실패 조건 |
|---|---|---|---|
| `fetchAll()` | - | `[LibraryBook]` (전체) | DB 접근 실패 |
| `fetchBy(status:)` | `ReadingStatus` | 해당 상태의 `[LibraryBook]` | DB 접근 실패 |
| `fetchBy(isbn:)` | `String` | `LibraryBook?` | DB 접근 실패 |
| `add(_:)` | `LibraryBook` | - | 동일 isbn 중복 추가 시 |
| `updateStatus(id:to:)` | `UUID`, `ReadingStatus` | - | id 없음 |
| `delete(id:)` | `UUID` | - | id 없음 |
| `addSession(_:to:)` | `ReadingSession`, `UUID` | - | bookId 없음 |
| `fetchSessions(for:)` | `UUID` | `[ReadingSession]` (최신순) | DB 접근 실패 |

---

## 5. 데이터 변환

### Naver API → LibraryBook

검색 결과(`Book`)를 서재에 추가할 때의 변환.

```swift
extension LibraryBook {
    convenience init(from book: Book, status: ReadingStatus) {
        self.init()
        self.id = UUID()
        self.isbn = book.id          // Book.id == ISBN
        self.title = book.title
        self.author = book.author
        self.publisher = book.publisher
        self.coverURL = book.coverURL
        self.bookDescription = book.description
        self.status = status
        self.addedAt = Date()
        self.startedAt = status == .reading ? Date() : nil
        self.sessions = []
    }
}
```

---

## 6. 집계 유틸리티

통계 계산에 사용하는 헬퍼. ViewModel 또는 별도 `StatsCalculator`에 위치.

```swift
// 세션 배열 → 총 독서 시간 (초)
func totalDuration(sessions: [ReadingSession]) -> TimeInterval {
    sessions.reduce(0) { $0 + $1.duration }
}

// 특정 날짜 범위의 세션 필터
func sessions(in range: DateInterval, from sessions: [ReadingSession]) -> [ReadingSession] {
    sessions.filter { range.contains($0.startTime) }
}

// 이번 주 DateInterval (월~일)
func currentWeekInterval() -> DateInterval {
    let calendar = Calendar.current
    let now = Date()
    let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)!.start
    let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
    return DateInterval(start: startOfWeek, end: endOfWeek)
}

// TimeInterval → "X시간 Y분" 포맷
func formatDuration(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    if hours > 0 {
        return "\(hours)시간 \(minutes)분"
    } else {
        return "\(minutes)분"
    }
}
```

---

## 7. SwiftData 컨테이너 설정

```swift
// BooktoryApp.swift
@main
struct BooktoryApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: [LibraryBook.self, ReadingSession.self])
    }
}
```

Preview 환경에서는 인메모리 컨테이너 사용:

```swift
// Preview helper
extension ModelContainer {
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: LibraryBook.self, ReadingSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return container
    }
}
```

---

## 8. 제약 사항

- **오프라인 전용**: 모든 데이터는 로컬 저장. 기기 변경 시 데이터 이전 불가 (iCloud 동기화는 Phase 3 선택 사항)
- **이미지 미저장**: `LibraryBook.coverURL`은 URL만 저장. 표지 이미지는 매번 네트워크에서 로드 (`AsyncImage`)
- **세션 최소 저장 기준**: 1분(60초) 미만 세션은 저장하지 않음
- **중복 추가 방지**: `isbn`을 기준으로 동일 책의 중복 추가를 차단
- **최소 지원 OS**: SwiftData는 iOS 17+ 필수
