# SRS — Phase 1: 핵심 서재 기능

## 1. 개요

Phase 1은 검색된 책을 서재에 추가하고, 독서 타이머와 세션을 연동하며,
서재/독서 탭을 완성하는 작업이다.
데이터 레이어(`srs/data-layer.md`)가 완성된 상태에서 시작한다.

### 1-1. 기능 범위

| 기능 ID | 기능명 | 의존 |
|---|---|---|
| 01 | 책 상세 화면 | 02 |
| 02 | 서재 액션 (바로읽기 / 읽고 싶은 책 저장) | — |
| 03 | 독서 탭 (읽고 있는 책 목록) | 02 |
| 04 | 타이머 ↔ 세션 저장 연동 | 03 |
| 05 | 서재 탭 (전체 책 목록 + 필터) | — |
| 06 | 서재 책 상세 + 세션 히스토리 | 04 |

### 1-2. 구현 순서 (의존 그래프 기반)

```
02 (서재 액션)
 ├──▶ 01 (책 상세)    ──▶ [SearchView 연결]
 ├──▶ 03 (독서 탭)   ──▶ 04 (타이머 세션) ──▶ 06 (서재 상세)
 └──▶ 05 (서재 탭)               └──────────────────────▶ 06
```

**권장 구현 순서:** 02 → 05 → 01 → 03 → 04 → 06

---

## 2. 아키텍처 결정사항 (공통 인프라)

Phase 1 전체가 공유하는 구조적 결정을 먼저 확정한다.

### 2-1. 최종 탭 구조

`MainView.swift`를 아래 구조로 재정의한다.

| 탭 인덱스 | 뷰 | 탭바 아이콘 | 탭바 레이블 |
|---|---|---|---|
| 0 | `ReadingTabView` | `book.fill` | 독서 |
| 1 | `SearchView` | `magnifyingglass` | 검색 |
| 2 | `RecordView` (미구현, `Text("기록")` placeholder) | `chart.bar` | 기록 |
| 3 | `LibraryTabView` | `books.vertical.fill` | 서재 |

> **변경 이유**: 현재 `MainView.swift`의 탭 순서(0=타이머, 1=기록, 2=검색, 3=empty)는
> `CLAUDE.md`의 의도된 탭 구조와 다르다. Phase 1에서 확정된 구조로 교체한다.

### 2-2. AppCoordinator — 탭 전환 & 타이머 자동 오픈

`MainView`가 직접 가진 `selectedTab` 상태를 `AppCoordinator`로 승격시킨다.
이를 통해 어느 ViewModel에서도 탭 전환과 타이머 오픈 트리거를 수행할 수 있다.

```swift
// Booktory/UI/App/AppCoordinator.swift
@MainActor
final class AppCoordinator: ObservableObject {
    @Published var selectedTab: Int = 0

    /// "바로 읽기" 후 독서 탭에서 자동 오픈할 책.
    /// ReadingTabView가 이 값을 감지해 fullScreenCover를 트리거한다.
    @Published var pendingBookForTimer: LibraryBook? = nil
}
```

`MainView`에서 생성 후 environment에 주입:

```swift
struct MainView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        TabView(selection: $coordinator.selectedTab) { ... }
            .environmentObject(coordinator)
    }
}
```

하위 뷰에서 사용:

```swift
@EnvironmentObject private var coordinator: AppCoordinator
```

### 2-3. Repository DI 패턴

ViewModel은 `LibraryRepositoryProtocol`을 init으로 주입받는다.
View는 `@Environment(\.modelContext)`로 컨텍스트를 얻어 Repository를 생성하고
ViewModel에 전달한다.

SwiftUI에서 `@StateObject`는 init 시점에 값을 확정하므로,
두 단계 View 구조를 사용한다.

```swift
// 외부 View: environment에서 context를 꺼내 내부 View에 전달
struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    let book: Book

    var body: some View {
        _BookDetailContent(
            book: book,
            repository: DefaultLibraryRepository(context: context)
        )
    }
}

// 내부 View: @StateObject 소유
private struct _BookDetailContent: View {
    @StateObject private var viewModel: BookDetailViewModel

    init(book: Book, repository: any LibraryRepositoryProtocol) {
        _viewModel = StateObject(
            wrappedValue: BookDetailViewModel(book: book, repository: repository)
        )
    }
    ...
}
```

> **Preview**: `ModelContainer.preview`(인메모리)에서 `DefaultLibraryRepository`를 생성해 주입.

### 2-4. 시간 포맷 유틸리티

`data-layer.md`의 `formatDuration` 함수를 공용 위치에 정의한다.

```swift
// Booktory/UI/Components/DurationFormatter.swift
enum DurationFormatter {
    /// TimeInterval(초) → "X시간 Y분" 또는 "Y분"
    static func format(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)시간 \(minutes)분" : "\(minutes)분"
    }
}
```

---

## 3. 신규 파일 목록

```
Booktory/
├── UI/
│   ├── App/
│   │   └── AppCoordinator.swift          ← (신규) 탭 전환 + 타이머 트리거
│   ├── Components/
│   │   └── DurationFormatter.swift       ← (신규) 시간 포맷 유틸
│   ├── Search/
│   │   ├── BookDetailView.swift          ← (신규) 01
│   │   └── BookDetailViewModel.swift     ← (신규) 01 + 02
│   ├── Reading/
│   │   ├── ReadingTabView.swift          ← (신규) 03
│   │   ├── ReadingTabViewModel.swift     ← (신규) 03
│   │   └── ReadingBookCard.swift         ← (신규) 03
│   ├── Library/
│   │   ├── LibraryTabView.swift          ← (신규) 05
│   │   ├── LibraryTabViewModel.swift     ← (신규) 05
│   │   ├── LibraryBookCard.swift         ← (신규) 05
│   │   ├── LibraryDetailView.swift       ← (신규) 06
│   │   └── LibraryDetailViewModel.swift  ← (신규) 06
│   └── Timer/
│       └── TimerViewModel.swift          ← (신규) 04 — 기존 TimerView 로직 분리
```

**수정이 필요한 기존 파일:**

| 파일 | 수정 내용 |
|---|---|
| `MainView.swift` | 탭 구조 재정의, AppCoordinator 주입 |
| `SearchView.swift` | NavigationStack 추가, 책 아이템 탭 → BookDetailView |
| `TimerView.swift` | LibraryBook 파라미터 수신, TimerViewModel 연동, 나가기 버튼 추가 |
| `TimerMainView.swift` | ReadingTabView로 대체 또는 리팩토링 |
| `BooktoryApp.swift` | modelContainer 설정 확인 (이미 완료되어 있으면 유지) |

---

## 4. 기능별 상세 스펙

### 4-1. [02] 서재 액션 — BookDetailViewModel

`BookDetailViewModel`이 바로읽기/읽고싶은 저장 두 액션을 모두 담당한다.

#### 상태 정의

```swift
enum BookDetailState {
    case idle
    case loading
    case error(String)
}

/// 해당 책의 현재 서재 상태. nil이면 서재에 없음.
typealias LibraryBookStatus = ReadingStatus?
```

#### 인터페이스

```swift
@MainActor
final class BookDetailViewModel: ObservableObject {
    // MARK: - Input
    let book: Book

    // MARK: - Output
    @Published private(set) var libraryStatus: ReadingStatus? = nil  // nil = 서재에 없음
    @Published private(set) var state: BookDetailState = .idle

    // MARK: - Init
    init(book: Book, repository: any LibraryRepositoryProtocol)

    // MARK: - Intent
    func loadLibraryStatus() async       // 화면 진입 시 서재 상태 확인
    func readNow() async                 // 바로 읽기
    func toggleWishlist() async          // 읽고 싶은 책 저장 / 취소
}
```

#### readNow() 동작 명세

```
1. state = .loading
2. fetchBy(isbn:) 호출
3a. 없으면: LibraryBook.create(from: book, status: .reading) → add(_:)
3b. wantToRead면: updateStatus(id:to: .reading)
3c. reading이면: 추가 동작 없음 (이미 독서 중)
3d. completed면: 동작 없음 (버튼 자체가 비활성)
4. libraryStatus = .reading
5. coordinator.selectedTab = 0 (독서 탭)
6. coordinator.pendingBookForTimer = 저장된 LibraryBook
7. state = .idle
8. 실패 시: state = .error("저장에 실패했습니다.")
```

#### toggleWishlist() 동작 명세

```
현재 libraryStatus가:
- nil: add(status: .wantToRead) → libraryStatus = .wantToRead
- wantToRead: delete(id:) → libraryStatus = nil
- reading / completed: 이 함수는 호출되지 않음 (버튼 비활성)
```

---

### 4-2. [01] 책 상세 화면 — BookDetailView

#### 화면 구성

```swift
struct BookDetailView: View {
    // 외부 wrapper (DI 처리)
    @Environment(\.modelContext) private var context
    let book: Book
}

private struct _BookDetailContent: View {
    @StateObject private var viewModel: BookDetailViewModel
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var isDescriptionExpanded = false
}
```

#### UI 컴포넌트 명세

| 영역 | 구현 |
|---|---|
| 책 표지 | `AsyncImage` 140×200pt, cornerRadius 8, 로딩 시 gray placeholder, 실패 시 `book` SF Symbol |
| 제목 | `.title3.bold()`, 멀티라인, 중앙 정렬 |
| 저자 · 출판사 | `author + " · " + publisher"`, `.subheadline`, `.secondary` |
| 책 소개 | 기본 4줄 (`lineLimit(4)`), "더 보기" / "접기" 버튼 토글, 짧으면 버튼 미표시 |
| [읽고 싶은 책에 저장] | outline 스타일 버튼, 조건별 레이블/활성화 상태 (아래 표 참고) |
| [바로 읽기] | filled 스타일 버튼, 조건별 레이블/활성화 상태 (아래 표 참고) |

#### 버튼 상태 매트릭스

| libraryStatus | [읽고 싶은 책에 저장] 버튼 | [바로 읽기] 버튼 |
|---|---|---|
| `nil` | "읽고 싶은 책에 저장" (활성) | "바로 읽기" (활성) |
| `.wantToRead` | "저장됨 ✓" (활성, 탭 시 제거) | "바로 읽기" (활성) |
| `.reading` | "저장됨 ✓" (비활성) | "읽고 있는 중" (비활성) |
| `.completed` | "저장됨 ✓" (비활성) | "완독한 책" (비활성) |

#### 네비게이션 연결

`SearchView`에 `NavigationStack`을 추가하고, 책 아이템을 `NavigationLink`로 감싼다.

```swift
// SearchView.swift 수정
var body: some View {
    NavigationStack {
        // 기존 VStack 내용 유지
        // ForEach 안의 HStack을 NavigationLink로 감싸기
        NavigationLink(value: book) {
            BookRowView(book: book)  // 기존 HStack 내용을 컴포넌트로 분리
        }
        .buttonStyle(.plain)
    }
    .navigationDestination(for: Book.self) { book in
        BookDetailView(book: book)
    }
}
```

---

### 4-3. [03] 독서 탭 — ReadingTabView / ReadingTabViewModel

#### ViewModel 인터페이스

```swift
@MainActor
final class ReadingTabViewModel: ObservableObject {
    @Published private(set) var readingBooks: [LibraryBook] = []
    @Published private(set) var isLoading = false

    init(repository: any LibraryRepositoryProtocol)

    func load() async    // .reading 상태 책 목록 fetch (lastSessionDate 내림차순)
}
```

**정렬 로직:**

```swift
// fetchBy(status: .reading) 후 클라이언트 정렬
readingBooks = books.sorted {
    let lhs = $0.lastSessionDate ?? $0.startedAt ?? $0.addedAt
    let rhs = $1.lastSessionDate ?? $1.startedAt ?? $1.addedAt
    return lhs > rhs
}
```

#### ReadingTabView 구성

```swift
struct ReadingTabView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var coordinator: AppCoordinator
}

private struct _ReadingTabContent: View {
    @StateObject private var viewModel: ReadingTabViewModel
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var selectedBook: LibraryBook? = nil    // fullScreenCover 트리거
    @State private var isTimerPresented = false
}
```

**pendingBookForTimer 처리:**

```swift
.onChange(of: coordinator.pendingBookForTimer) { _, book in
    guard let book else { return }
    selectedBook = book
    isTimerPresented = true
    coordinator.pendingBookForTimer = nil
}
.fullScreenCover(isPresented: $isTimerPresented) {
    if let book = selectedBook {
        TimerView(book: book, autoStart: true)
    }
}
```

**데이터 갱신:** `.task` + `.onReceive(NotificationCenter ...)`는 사용하지 않는다.
SwiftData의 `@Query`를 ViewModel에서 직접 사용하기 어려우므로,
탭 진입 시 `viewModel.load()`, 타이머 dismiss 후 `viewModel.load()` 재호출로 갱신한다.

#### ReadingBookCard 컴포넌트

```swift
struct ReadingBookCard: View {
    let book: LibraryBook
    let onReadNow: () -> Void
}
```

| 요소 | 명세 |
|---|---|
| 표지 | `AsyncImage` 60×90pt |
| 제목 | `.headline`, lineLimit(1), 말줄임 |
| 저자 | `.subheadline`, `.secondary` |
| 누적 시간 | `DurationFormatter.format(book.totalDuration)` |
| [이어 읽기] 버튼 | `.bordered` 스타일, 탭 시 `onReadNow()` 콜백 |

#### Empty State

```swift
struct ReadingEmptyView: View {
    let onSearchTapped: () -> Void
}
```

- SF Symbol: `books.vertical` (large, secondary color)
- 메인 문구: "읽고 있는 책이 없어요"
- 서브 문구: "책을 검색해서 독서를 시작해보세요"
- CTA 버튼: "책 검색하기 →" → `coordinator.selectedTab = 1`

---

### 4-4. [04] 타이머 ↔ 세션 저장 — TimerViewModel

기존 `TimerView`의 타이머 로직을 `TimerViewModel`로 분리하고,
세션 저장 로직을 추가한다.

#### TimerViewModel 인터페이스

```swift
@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: - Output
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var isRunning = false

    // MARK: - Init
    /// - autoStart: true면 진입 즉시 타이머 시작
    init(book: LibraryBook, repository: any LibraryRepositoryProtocol, autoStart: Bool = false)

    // MARK: - Intent
    func start()
    func pause()
    func resume()

    /// 타이머를 종료하고 세션을 저장한다.
    /// - Returns: 저장 성공 여부 (1분 미만이면 false 반환, 저장 안 함)
    @discardableResult
    func stopAndSave() async -> Bool
}
```

#### stopAndSave() 동작 명세

```
1. isRunning이면 pause() 호출 (현재까지 elapsed 확정)
2. elapsed < 60초이면 → 저장 없이 return false
3. endTime = Date()
4. ReadingSession 생성:
   - id = UUID()
   - libraryBookId = book.id
   - startTime = sessionStartDate (타이머 처음 시작 시각 기록 필요)
   - endTime = endTime
   - duration = elapsed
5. addSession(session, to: book.id) 호출
6. 실패 시 Logger.error 기록, UI 에러 표시 없음
7. return true
```

#### TimerView 수정 명세

```swift
struct TimerView: View {
    // 기존 @State 타이머 로직 제거
    // @StateObject private var viewModel: TimerViewModel 추가
    let book: LibraryBook
    let autoStart: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
}
```

**나가기 버튼 플로우:**
- 타이머 실행 중이면 → Alert "독서를 종료하고 저장할까요?" → 확인: `stopAndSave()` 후 dismiss
- 정지 상태면 → 즉시 `stopAndSave()` 후 dismiss

**헤더 표시:** 상단에 `book.title` (`.headline`, lineLimit(1))

---

### 4-5. [05] 서재 탭 — LibraryTabView / LibraryTabViewModel

#### ViewModel 인터페이스

```swift
@MainActor
final class LibraryTabViewModel: ObservableObject {
    @Published private(set) var books: [LibraryBook] = []
    @Published var selectedFilter: ReadingStatus? = nil  // nil = 전체

    init(repository: any LibraryRepositoryProtocol)

    func load() async
}
```

`load()` 내부:
- `selectedFilter == nil`: `fetchAll()` (addedAt 내림차순, Repository 기본 정렬 사용)
- 그 외: `fetchBy(status: selectedFilter!)`

> `selectedFilter` 변경 시 `load()` 재호출 — View에서 `.onChange(of: viewModel.selectedFilter)` 처리

#### LibraryTabView 구성

```swift
NavigationStack {
    VStack(spacing: 0) {
        FilterTabBar(selected: $viewModel.selectedFilter)
        bookGrid
    }
    .navigationTitle("서재")
    .navigationBarTitleDisplayMode(.large)
}
```

#### FilterTabBar 컴포넌트

```swift
struct FilterTabBar: View {
    @Binding var selected: ReadingStatus?
}
```

- 수평 스크롤 `ScrollView(.horizontal, showsIndicators: false)`
- 탭 항목: "전체" (nil), "읽고 있는", "완독한", "읽고 싶은"
- 선택된 탭: `Capsule` background + 흰색 텍스트, 미선택: `.secondary` 텍스트

#### LibraryBookCard 컴포넌트

```swift
struct LibraryBookCard: View {
    let book: LibraryBook
}
```

- 표지: `AsyncImage` full-width, aspectRatio(2/3, .fill), cornerRadius 8
- 제목: `.caption.bold()`, lineLimit(2)
- 저자: `.caption2`, `.secondary`, lineLimit(1)

**그리드 설정:**

```swift
let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
]
LazyVGrid(columns: columns, spacing: 16) { ... }
.padding(.horizontal, 16)
```

#### Empty State (탭별 메시지)

| selectedFilter | 메시지 | CTA |
|---|---|---|
| nil (전체) | "서재가 비어있어요" | "책 검색하기 →" → `selectedTab = 1` |
| `.reading` | "읽고 있는 책이 없어요" | — |
| `.completed` | "완독한 책이 없어요" | — |
| `.wantToRead` | "읽고 싶은 책이 없어요" | — |

#### 네비게이션

```swift
.navigationDestination(for: LibraryBook.self) { book in
    LibraryDetailView(bookId: book.id)
}
```

---

### 4-6. [06] 서재 책 상세 + 세션 히스토리 — LibraryDetailView / LibraryDetailViewModel

#### ViewModel 인터페이스

```swift
@MainActor
final class LibraryDetailViewModel: ObservableObject {
    @Published private(set) var book: LibraryBook? = nil
    @Published private(set) var sessions: [ReadingSession] = []
    @Published private(set) var state: LibraryDetailState = .idle
    @Published var showDeleteConfirm = false

    init(bookId: UUID, repository: any LibraryRepositoryProtocol)

    func load() async
    func markAsCompleted() async
    func markAsReading() async       // wantToRead → reading
    func deleteBook() async          // 삭제 후 dismiss 트리거
}

enum LibraryDetailState {
    case idle
    case loading
    case error(String)
    case deleted            // 삭제 완료 → View에서 dismiss
}
```

#### 화면 구성

```swift
ScrollView {
    VStack(alignment: .leading, spacing: 24) {
        BookHeaderSection(book: book)
        ReadingStatsSection(book: book, sessions: sessions)
        SessionHistorySection(sessions: sessions)
    }
}
.safeAreaInset(edge: .bottom) {
    ActionButtonSection(book: book, viewModel: viewModel)
}
```

#### BookHeaderSection

| 요소 | 명세 |
|---|---|
| 표지 | `AsyncImage` 80×120pt, cornerRadius 6 |
| 제목 | `.title3.bold()` |
| 저자 · 출판사 | `author + " · " + publisher`, `.subheadline`, `.secondary` |

#### ReadingStatsSection

| 항목 | 데이터 | 포맷 |
|---|---|---|
| 총 독서 시간 | `book.totalDuration` | `DurationFormatter.format()` |
| 총 독서 횟수 | `sessions.count` | `N회` |
| 서재 추가일 | `book.addedAt` | `yyyy.MM.dd` |
| 독서 시작일 | `book.startedAt` | `yyyy.MM.dd` / 없으면 미표시 |
| 완독일 | `book.completedAt` | `yyyy.MM.dd` / 없으면 미표시 |

#### SessionHistorySection

각 세션 행:

```
2025.03.01  오전 10:30 시작   40분
```

- 날짜: `yyyy.MM.dd`
- 시작 시간: `a h:mm` (오전/오후 h:mm)
- 독서 시간: `DurationFormatter.format(session.duration)`
- 최신 세션이 상단 (ViewModel에서 `startTime` 내림차순 정렬 후 반환)
- 세션 없을 시: "아직 독서 기록이 없어요" 안내 텍스트

#### ActionButtonSection

| book.status | 표시 버튼 |
|---|---|
| `.wantToRead` | "읽기 시작" (→ `.reading` 전환) |
| `.reading` | "완독으로 표시" (→ `.completed` 전환) |
| `.completed` | 버튼 없음 (완독 완료 메시지 텍스트만) |

#### 삭제 기능

- 네비게이션 바 trailing에 `Menu` 버튼 (···)
- 메뉴 항목: "서재에서 삭제" → `showDeleteConfirm = true`
- Confirm Alert: "서재에서 삭제하면 모든 독서 기록도 삭제됩니다."
- 확인 → `deleteBook()` → state = .deleted → View에서 dismiss

```swift
.onChange(of: viewModel.state) { _, state in
    if case .deleted = state {
        dismiss()
    }
}
```

---

## 5. MainView 수정 명세

```swift
struct MainView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ReadingTabView()
                .tabItem { Label("독서", systemImage: "book.fill") }
                .tag(0)

            NavigationStack { SearchView() }
                .tabItem { Label("검색", systemImage: "magnifyingglass") }
                .tag(1)

            Text("기록")  // Phase 2
                .tabItem { Label("기록", systemImage: "chart.bar") }
                .tag(2)

            LibraryTabView()
                .tabItem { Label("서재", systemImage: "books.vertical.fill") }
                .tag(3)
        }
        .environmentObject(coordinator)
    }
}
```

> `SearchView`는 tab 내부에서 `NavigationStack`으로 감싼다.
> `BookDetailView`는 SearchView와 같은 NavigationStack에 push된다.

---

## 6. Preview 전략

각 View의 Preview는 인메모리 컨테이너를 사용한다.

```swift
#Preview {
    let container = ModelContainer.preview
    let repository = DefaultLibraryRepository(context: container.mainContext)

    // 필요한 경우 샘플 데이터 삽입
    let sampleBook = LibraryBook(
        isbn: "9788966261970",
        title: "클린 코드",
        author: "로버트 C. 마틴",
        publisher: "인사이트",
        coverURL: "",
        bookDescription: "좋은 코드를 작성하는 방법",
        status: .reading
    )
    container.mainContext.insert(sampleBook)

    return SomeView(repository: repository)
        .modelContainer(container)
        .environmentObject(AppCoordinator())
}
```

---

## 7. 에러 처리 정책

| 상황 | 처리 |
|---|---|
| 서재 추가/상태변경/삭제 실패 | `.error(String)` 상태 → View에서 `Alert` 표시, 한국어 메시지 |
| 세션 저장 실패 | UI 표시 없음, `Logger.error` 기록 |
| 데이터 조회 실패 | 빈 목록 표시 + Logger 기록 |
| 이미지 로딩 실패 | SF Symbol fallback (`book`) |
| 중복 ISBN 추가 시도 | `RepositoryError.duplicateISBN` → 이미 있는 상태로 `libraryStatus` 업데이트 |

---

## 8. 완료 기준 (Phase 1 전체)

- [ ] 검색 결과 아이템 탭 → 책 상세 화면 push 네비게이션 동작
- [ ] 책 상세: 서재 상태에 따라 버튼 레이블/활성화 상태가 올바르게 표시됨
- [ ] [바로 읽기] 탭 → 독서 탭(0)으로 전환 + 타이머 자동 오픈
- [ ] [읽고 싶은 책에 저장] 탭 → 저장/취소 토글 동작
- [ ] 독서 탭: reading 상태 책 목록이 최근 독서순으로 표시됨
- [ ] 독서 탭: 책 없을 때 Empty State 표시, [책 검색하기] → 검색 탭 전환
- [ ] 타이머: 선택한 책 제목 표시, 나가기 시 세션 저장 (1분 이상만)
- [ ] 타이머: 일시정지 후 나가도 일시정지까지의 시간으로 세션 저장
- [ ] 서재 탭: 4개 필터 탭 동작, 각 상태 책이 올바르게 필터링됨
- [ ] 서재 탭: 책 추가/삭제 후 목록 갱신됨
- [ ] 서재 상세: 책 정보 + 독서 통계 + 세션 히스토리 표시
- [ ] 서재 상세: 완독/읽기시작 상태 변경 동작
- [ ] 서재 상세: 삭제 확인 후 삭제 → 이전 화면으로 pop
- [ ] 모든 View에 SwiftUI Preview 작성
- [ ] 동일 ISBN 책은 중복으로 서재에 추가되지 않음
