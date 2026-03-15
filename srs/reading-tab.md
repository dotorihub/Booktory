# SRS — 독서 탭 (읽고 있는 책 목록 + 타이머 진입)

> Phase 1 — `04-reading-tab` 구현 기술 명세

---

## 1. 개요

탭 0(독서)의 메인 화면. `reading` 상태인 책들을 카드 목록으로 보여주고,
각 카드의 [이어 읽기] 버튼으로 타이머 화면(`fullScreenCover`)을 오픈하는 진입점이다.
`03-book-detail`의 [바로 읽기] 액션 이후 `AppCoordinator.pendingAutoOpenBookId`를 수신해 타이머를 자동으로 오픈한다.

**의존**: `srs/data-layer.md`, `srs/library-action.md`, `srs/book-detail.md`

**마이그레이션**: 기존 `TimerMainView`(임시 플레이스홀더)를 `ReadingTabView`로 완전 대체한다.

---

## 2. 컴포넌트 구조

```
ReadingTabView                          ← 탭 루트 (NavigationStack)
├── [books 있음]
│   └── ScrollView
│       └── VStack
│           └── ReadingBookCard (N개)   ← 책 카드 리스트
└── [books 없음]
    └── ReadingEmptyView               ← Empty State
```

---

## 3. ViewModel 설계

### `ReadingTabViewModel`

```swift
@MainActor
final class ReadingTabViewModel: ObservableObject {

    // MARK: - 상태

    @Published private(set) var books: [LibraryBook] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    /// 현재 타이머에 열려 있는 책 (fullScreenCover 트리거)
    @Published var selectedBook: LibraryBook? = nil

    private let repository: any LibraryRepositoryProtocol

    init(repository: any LibraryRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 공개 인터페이스

    /// 탭 진입 / 갱신 시 호출
    func loadBooks() async

    /// 특정 책의 누적 독서 시간 (초 단위)
    func totalReadingSeconds(for book: LibraryBook) -> TimeInterval
}
```

### 정렬 규칙

| 조건 | 정렬 기준 |
|---|---|
| 세션이 있는 책 | 가장 최근 세션 `startTime` 내림차순 |
| 세션이 없는 책 | `startedAt` 내림차순 |

> 세션이 있는 책을 먼저 배치하고, 그 다음 세션이 없는 책을 `startedAt` 기준으로 이어 붙인다.

### 누적 독서 시간 계산

```swift
func totalReadingSeconds(for book: LibraryBook) -> TimeInterval {
    // LibraryBook.sessions 는 @Relationship으로 이미 로드된 상태
    book.sessions.reduce(0) { $0 + $1.duration }
}
```

> `05-timer-session` 구현 이전에는 세션이 없으므로 항상 0을 반환한다.
> 포맷 로직은 ViewModel에서 처리하지 않고 View의 헬퍼 함수로 분리한다.

---

## 4. 컴포넌트 명세

### 4-1. ReadingBookCard

```
┌──────────────────────────────────┐
│  ┌──────┐  제목 (1줄 말줄임)     │
│  │      │  저자                  │
│  │[표지]│  총 0시간 00분         │
│  │      │            [이어 읽기] │
│  └──────┘                        │
└──────────────────────────────────┘
```

```swift
struct ReadingBookCard: View {
    let book: LibraryBook
    let totalSeconds: TimeInterval
    let onResume: () -> Void         // [이어 읽기] 탭 콜백
}
```

**레이아웃 상세:**
- `HStack(alignment: .top, spacing: 12)`
- 좌: `AsyncImage` — `width: 70, height: 100`, `cornerRadius: 6`, scaledToFit
- 우: `VStack(alignment: .leading, spacing: 4)`
  - 제목: `.headline`, `lineLimit(1)`
  - 저자: `.subheadline`, `.secondary`
  - 누적 시간: `.footnote`, `.secondary`, `formatReadingTime(totalSeconds)` 출력
  - [이어 읽기]: `.borderedProminent`, trailing 정렬, `frame(maxWidth: .infinity, alignment: .trailing)`
- 카드 전체: `.background(.background)`, `cornerRadius(12)`, `shadow(radius: 2)`
- 패딩: `padding(16)`

**누적 시간 포맷:**
```swift
func formatReadingTime(_ seconds: TimeInterval) -> String {
    let totalMinutes = Int(seconds) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    if hours > 0 {
        return "총 \(hours)시간 \(String(format: "%02d", minutes))분"
    } else {
        return "총 \(String(format: "%02d", minutes))분"
    }
}
```

---

### 4-2. ReadingEmptyView

```
┌─────────────────────────────┐
│                             │
│        [book.open]          │  ← SF Symbol, .largeTitle 크기
│  읽고 있는 책이 없어요       │
│  독서를 시작해보세요         │  ← .subheadline, secondary
│                             │
│     [책 검색하기 →]          │  ← .borderedProminent CTA
│                             │
└─────────────────────────────┘
```

```swift
struct ReadingEmptyView: View {
    let onSearchTap: () -> Void
}
```

---

## 5. 타이머 연동

### 5-1. [이어 읽기] 탭 → 타이머 오픈

```swift
// ReadingTabView (또는 ReadingTabContentView)
.fullScreenCover(item: $viewModel.selectedBook) { book in
    TimerView(book: book)
}
```

`selectedBook`에 `LibraryBook`을 설정하면 `fullScreenCover`가 트리거된다.

> `TimerView`에 `book: LibraryBook` 파라미터를 추가해 제목·저자·표지를 동적으로 표시한다.
> 타이머 세션 저장(시작/종료/저장)은 `05-timer-session` 스코프.

### 5-2. `pendingAutoOpenBookId` 수신 — 자동 오픈

`03-book-detail`의 [바로 읽기] 탭 후 독서 탭으로 전환될 때 자동으로 타이머를 연다.

```swift
// ReadingTabContentView
.onChange(of: coordinator.pendingAutoOpenBookId) { _, bookId in
    guard let bookId else { return }
    // books 목록에서 해당 책 찾기
    if let book = viewModel.books.first(where: { $0.id == bookId }) {
        viewModel.selectedBook = book
    }
    coordinator.pendingAutoOpenBookId = nil  // 소비 후 반드시 초기화
}
```

> `pendingAutoOpenBookId`가 설정되는 시점에 `books`가 아직 로드되지 않았을 수 있다.
> 이 경우 `loadBooks()` 완료 후 재확인하는 로직이 필요하다 (아래 §6 데이터 흐름 참고).

---

## 6. 데이터 흐름

```
ReadingTabView.onAppear
  → viewModel.loadBooks()
      → repository.fetchBy(status: .reading)
      → books 정렬 적용
      → @Published books 업데이트
          → View 재렌더링

      [pendingAutoOpenBookId 처리]
      → coordinator.pendingAutoOpenBookId 확인
      → books 중 해당 id 찾아 selectedBook 설정
      → pendingAutoOpenBookId = nil

coordinator.pendingAutoOpenBookId 변경 감지 (onChange)
  → loadBooks()가 완료된 상태라면 즉시 selectedBook 설정
  → 아직 로드 중이라면 loadBooks() 내부에서 후처리
```

### `loadBooks()` 구현 패턴

```swift
func loadBooks() async {
    isLoading = true
    defer { isLoading = false }
    do {
        let fetched = try repository.fetchBy(status: .reading)
        books = sorted(fetched)

        // 로드 완료 후 pendingAutoOpen 처리 (coordinator는 외부 주입)
        if let pendingId = pendingAutoOpenId {
            selectedBook = books.first { $0.id == pendingId }
            pendingAutoOpenId = nil
        }
    } catch {
        logger.error("독서 탭 로드 실패: \(error.localizedDescription)")
        errorMessage = "목록을 불러오지 못했습니다."
    }
}
```

> `ReadingTabViewModel`은 `coordinator` 대신 별도 `pendingAutoOpenId: UUID?` 프로퍼티를 갖고,
> View 레이어에서 `coordinator.pendingAutoOpenBookId`를 `viewModel.pendingAutoOpenId`에 전달한다.
> 이로써 ViewModel이 AppCoordinator에 직접 의존하지 않아 테스트 가능성이 유지된다.

---

## 7. TimerView 수정 사항

현재 `TimerView`는 제목·저자가 하드코딩되어 있다.
이번 구현에서 `book: LibraryBook` 파라미터를 추가해 실제 책 정보를 표시한다.

```swift
// 변경 전
struct TimerView: View { ... }

// 변경 후
struct TimerView: View {
    let book: LibraryBook
    // 기존 타이머 로직 유지
    // book.title, book.author, book.coverURL 사용
}
```

> 세션 저장 로직(시작/종료 시 ReadingSession 생성)은 `05-timer-session` 스코프이므로 추가하지 않는다.

---

## 8. MainView 마이그레이션

`TimerMainView`를 `MainView`에서 제거하고 `ReadingTabView`로 교체한다.

```swift
// MainView.swift — 변경 후
ReadingTabView()
    .tabItem { Label("독서", systemImage: "book.fill") }
    .tag(AppCoordinator.Tab.reading)
```

`TimerMainView`는 완전히 삭제한다.

---

## 9. 실시간 반영 전략

현 단계에서는 `@Query` 기반 실시간 반영 대신 **이벤트 기반 재로드**로 처리한다.

| 이벤트 | 처리 |
|---|---|
| 탭 진입 (`onAppear`) | `loadBooks()` 호출 |
| `pendingAutoOpenBookId` 수신 후 돌아옴 | `onAppear` 재트리거로 목록 갱신 |
| `fullScreenCover` 닫기 | `onDismiss`에서 `loadBooks()` 호출 |

> `@Query` 기반 실시간 반영은 `06-library-detail` 구현 후 패턴 결정.

---

## 10. 에러 처리

```swift
func loadBooks() async {
    ...
    } catch {
        logger.error("독서 탭 로드 실패: \(error.localizedDescription)")
        errorMessage = "목록을 불러오지 못했습니다."
    }
}
```

```swift
// View
.alert("오류", isPresented: Binding(
    get: { viewModel.errorMessage != nil },
    set: { if !$0 { viewModel.errorMessage = nil } }
)) {
    Button("확인", role: .cancel) { viewModel.errorMessage = nil }
} message: {
    Text(viewModel.errorMessage ?? "")
}
```

---

## 11. Preview 전략

```swift
#Preview("책 있는 경우") {
    let container = ModelContainer.previewWithSampleData
    let repo = DefaultLibraryRepository(context: container.mainContext)
    return ReadingTabView(viewModel: ReadingTabViewModel(repository: repo))
        .environmentObject(AppCoordinator())
        .modelContainer(container)
}

#Preview("Empty State") {
    ReadingTabView(viewModel: ReadingTabViewModel(
        repository: PreviewLibraryRepository.empty()
    ))
    .environmentObject(AppCoordinator())
}
```

> `ModelContainer.previewWithSampleData`의 더미 데이터 중 `.reading` 상태 책이 포함되어 있으므로
> 별도 데이터 주입 없이도 카드 목록 Preview가 가능하다.

---

## 12. 작업 파일 목록

| 파일 경로 | 작업 |
|---|---|
| `UI/Reading/ReadingTabView.swift` | 기존 플레이스홀더 → 전체 구현으로 교체 |
| `UI/Reading/ReadingTabViewModel.swift` | 신규 생성 |
| `UI/Reading/Components/ReadingBookCard.swift` | 신규 생성 |
| `UI/Reading/Components/ReadingEmptyView.swift` | 신규 생성 |
| `UI/Timer/TimerView.swift` | `book: LibraryBook` 파라미터 추가 |
| `UI/Main/MainView.swift` | `TimerMainView` → `ReadingTabView` 교체 |
| `UI/Timer/TimerMainView.swift` | 삭제 |

---

## 13. 완료 기준

- [ ] `reading` 상태 책 목록이 카드 형태로 표시됨
- [ ] 카드에 표지·제목·저자·누적 독서 시간이 표시됨
- [ ] 카드 정렬: 최근 세션 → `startedAt` 기준 내림차순
- [ ] [이어 읽기] 탭 시 해당 책의 타이머 `fullScreenCover` 오픈
- [ ] 타이머 화면에 올바른 책 제목·저자가 표시됨
- [ ] Empty State: "읽고 있는 책이 없어요" + [책 검색하기] 버튼
- [ ] [책 검색하기] 탭 시 검색 탭(탭 1)으로 전환
- [ ] `pendingAutoOpenBookId` 수신 시 타이머 자동 오픈
- [ ] Preview 2종 (카드 목록 / Empty State) 정상 표시
- [ ] `TimerMainView` 코드 완전 제거

---

## 14. 제약 사항

- 타이머 세션 저장(시작·종료 시 `ReadingSession` 생성)은 `05-timer-session` 스코프
- 누적 독서 시간은 세션 데이터가 없는 현 단계에서 "총 00분"으로 표시됨
- `@Query` 기반 실시간 반영은 `06-library-detail` 이후 결정
- `TimerView` 수정 범위는 book 파라미터 주입 및 UI 표시에 한정 (타이머 로직 변경 없음)
- 1분 미만 세션 저장 규칙은 `05-timer-session` 스코프
