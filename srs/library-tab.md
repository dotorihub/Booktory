# SRS — 서재 탭 (책 목록 + 필터)

> Phase 1 — `02-library-tab` 구현 기술 명세

---

## 1. 개요

탭 3(서재)의 메인 화면. 사용자의 서재에 등록된 모든 책을 상태별 필터와 레이아웃 전환(그리드/리스트)으로 탐색한다.
책 카드 탭 시 `06-library-detail`(상세/히스토리 화면)으로 이동하는 진입점이다.

**의존**: `srs/data-layer.md` (`LibraryRepositoryProtocol`, `LibraryBook`, `ReadingStatus`)
> `03-book-detail` 미개발 상태이므로, 카드 탭 동작은 NavigationLink 구조만 잡고 목적지는 플레이스홀더로 처리한다.

---

## 2. 컴포넌트 구조

```
LibraryTabView                          ← 탭 루트 뷰 (NavigationStack)
├── LibraryFilterTabView                ← 수평 스크롤 필터 탭
├── Menu (그리드/리스트 전환 드롭다운)
├── [books 있음]
│   ├── LibraryGridView                 ← LazyVGrid 2열
│   │   └── LibraryBookGridCard         ← 표지만 표시
│   └── LibraryListView                 ← List
│       └── LibraryBookListRow          ← 표지 + 제목 + 저자
└── [books 없음]
    └── LibraryEmptyView                ← 탭별 Empty State
```

---

## 3. ViewModel 설계

### `LibraryTabViewModel`

```swift
@MainActor
final class LibraryTabViewModel: ObservableObject {

    // MARK: - 상태

    @Published private(set) var books: [LibraryBook] = []
    @Published var selectedFilter: ReadingStatus? = nil   // nil = 전체
    @Published var layoutStyle: LibraryLayoutStyle = .grid
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: any LibraryRepositoryProtocol

    init(repository: any LibraryRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - 공개 인터페이스

    /// 탭 진입 / 필터 변경 시 호출
    func loadBooks() async

    /// 필터 전환
    func selectFilter(_ filter: ReadingStatus?) async
}
```

### 정렬 규칙

| `selectedFilter` | 정렬 기준 |
|---|---|
| `nil` (전체) | `addedAt` 내림차순 |
| `.reading` | 최근 세션의 `startTime` 내림차순, 세션 없으면 `startedAt` 내림차순 |
| `.completed` | `completedAt` 내림차순 |
| `.wantToRead` | `addedAt` 내림차순 |

> `.reading` 정렬은 `fetchSessions(for:)` 없이 `LibraryBook.sessions`의 `max(\.startTime)` 으로 계산한다.

### 레이아웃 상태 영속화

```swift
enum LibraryLayoutStyle: String {
    case grid
    case list
}

// ViewModel 내부 또는 @AppStorage로 사용자 선택 유지
@AppStorage("libraryLayoutStyle") var layoutStyle: LibraryLayoutStyle = .grid
```

---

## 4. 컴포넌트 명세

### 4-1. LibraryFilterTabView

수평 스크롤 가능한 필터 탭. 선택된 탭을 시각적으로 구분한다.

```
전체  읽고 있는  완독한  읽고 싶은
 ↑
선택 시: 진한 foreground + underline 또는 background pill
```

```swift
struct LibraryFilterTabView: View {
    @Binding var selectedFilter: ReadingStatus?
    // 탭 항목: [(label: String, filter: ReadingStatus?)]
    // [("전체", nil), ("읽고 있는", .reading), ("완독한", .completed), ("읽고 싶은", .wantToRead)]
}
```

**스타일:**
- 미선택: `.secondary` foreground
- 선택: `.primary` foreground + 하단 인디케이터 (2pt, 앱 accent color)
- ScrollView(.horizontal, showsIndicators: false)

---

### 4-2. 레이아웃 전환 드롭다운

NavigationBar trailing 영역에 Menu 버튼 배치.

```swift
// NavigationBar trailing
Menu {
    Button { viewModel.layoutStyle = .grid } label: {
        Label("그리드", systemImage: "square.grid.2x2")
    }
    Button { viewModel.layoutStyle = .list } label: {
        Label("리스트", systemImage: "list.bullet")
    }
} label: {
    Image(systemName: viewModel.layoutStyle == .grid ? "square.grid.2x2" : "list.bullet")
        .accessibilityLabel("레이아웃 변경")
}
```

---

### 4-3. LibraryBookGridCard

그리드 모드 카드. **표지 이미지만** 표시한다.

```
┌──────────┐
│          │  ← 1:1 정사각형 컨테이너
│  [표지]  │  ← .scaledToFit — 이미지를 잘리지 않게 컨테이너 안에 맞춤
│          │
└──────────┘
```

```swift
struct LibraryBookGridCard: View {
    let book: LibraryBook
    // AsyncImage(url: URL(string: book.coverURL)) { phase in
    //     switch phase {
    //     case .success(let image):
    //         image
    //             .resizable()
    //             .scaledToFit()          // fit: 이미지 전체가 보이도록
    //     case .failure:
    //         Image(systemName: "book.closed")
    //             .resizable()
    //             .scaledToFit()
    //             .foregroundStyle(.quaternary)
    //     case .empty:
    //         RoundedRectangle(cornerRadius: 6)
    //             .fill(.quaternary)
    //     @unknown default:
    //         EmptyView()
    //     }
    // }
    // .frame(maxWidth: .infinity)
    // .aspectRatio(1, contentMode: .fit)  // 1:1 정사각형 컨테이너
    // .background(Color(.secondarySystemBackground))
    // .cornerRadius(6)
}
```

---

### 4-4. LibraryBookListRow

리스트 모드 행. `HStack`: 좌측 표지 이미지 + 우측 제목/저자.

```
┌────┬───────────────────┐
│    │ 제목 (2줄 말줄임)  │
│[fit│ 저자               │
│ 1:1│                   │
│   ]│                   │
└────┴───────────────────┘
```

```swift
struct LibraryBookListRow: View {
    let book: LibraryBook
    // HStack(alignment: .center, spacing: 12) {
    //
    //     AsyncImage(url: URL(string: book.coverURL)) { phase in
    //         switch phase {
    //         case .success(let image):
    //             image
    //                 .resizable()
    //                 .scaledToFit()       // fit: 이미지 잘리지 않게
    //         case .failure:
    //             Image(systemName: "book.closed")
    //                 .resizable()
    //                 .scaledToFit()
    //                 .foregroundStyle(.quaternary)
    //         case .empty:
    //             RoundedRectangle(cornerRadius: 4)
    //                 .fill(.quaternary)
    //         @unknown default:
    //             EmptyView()
    //         }
    //     }
    //     .frame(width: 60, height: 60)    // 1:1 정사각형 고정
    //     .background(Color(.secondarySystemBackground))
    //     .cornerRadius(4)
    //
    //     VStack(alignment: .leading, spacing: 4) {
    //         Text(book.title)
    //             .lineLimit(2)
    //             .font(.body.weight(.medium))
    //         Text(book.author)
    //             .lineLimit(1)
    //             .font(.subheadline)
    //             .foregroundStyle(.secondary)
    //     }
    // }
}
```

---

### 4-5. LibraryEmptyView

필터별 빈 상태 안내 화면.

| 필터 | 아이콘 | 안내 문구 | CTA |
|---|---|---|---|
| 전체 | `books.closed` | 서재가 비어 있어요 | [책 보러 가기] → 검색 탭 전환 |
| 읽고 있는 | `book.open` | 읽고 있는 책이 없어요 | 없음 |
| 완독한 | `checkmark.seal` | 완독한 책이 없어요 | 없음 |
| 읽고 싶은 | `bookmark` | 읽고 싶은 책이 없어요 | 없음 |

```swift
struct LibraryEmptyView: View {
    let filter: ReadingStatus?
    let onSearchTap: (() -> Void)?    // 전체 탭 전용 CTA 콜백
}
```

---

### 4-6. 설정 진입점

NavigationBar trailing 우측에 톱니바퀴 아이콘. 설정 화면은 `06-library-detail` 이후 스코프이므로 플레이스홀더 NavigationLink만 연결.

```swift
// NavigationBar trailing (레이아웃 드롭다운 좌측)
NavigationLink {
    SettingsPlaceholderView()
} label: {
    Image(systemName: "gearshape")
        .accessibilityLabel("설정")
}
```

---

## 5. 더미 데이터 및 Preview 전략

검색 탭 → 서재 추가 기능이 미개발 상태이므로, Preview에서는 `PreviewLibraryRepository`에 더미 데이터를 주입해 UI를 검증한다.

### 5-1. 더미 데이터 정의

```swift
// LibraryBook+Preview.swift  (UI/Library/ 폴더 또는 Preview Content 그룹)
// @Model 인스턴스는 ModelContainer 없이 생성 가능하나, SwiftData 내부 기능을 쓰려면
// in-memory container가 필요하다. Preview에서는 PreviewLibraryRepository를 사용한다.

extension PreviewLibraryRepository {

    /// 다양한 상태의 더미 책이 채워진 Repository 반환
    static func populated() -> PreviewLibraryRepository {
        let repo = PreviewLibraryRepository()

        let books: [(String, String, String, ReadingStatus)] = [
            ("9791162540145", "클린 코드", "로버트 C. 마틴", .reading),
            ("9791185475219", "함께 자라기", "김창준",          .reading),
            ("9788966261208", "도메인 주도 설계", "에릭 에반스", .completed),
            ("9791158391690", "실용주의 프로그래머", "앤드류 헌트", .completed),
            ("9788966261154", "테스트 주도 개발", "켄트 백",     .wantToRead),
            ("9791191866018", "소프트웨어 장인",  "산드로 만쿠소", .wantToRead),
        ]

        for (isbn, title, author, status) in books {
            let book = LibraryBook(
                isbn: isbn,
                title: title,
                author: author,
                publisher: "인사이트",
                coverURL: "",   // AsyncImage 에러 → fallback 표시
                bookDescription: "",
                status: status
            )
            try? repo.add(book)
        }
        return repo
    }

    /// 서재가 비어있는 Empty State 확인용
    static func empty() -> PreviewLibraryRepository {
        PreviewLibraryRepository()
    }
}
```

### 5-2. Preview 구성

```swift
#Preview("그리드 - 전체") {
    LibraryTabView(viewModel: LibraryTabViewModel(
        repository: .populated()
    ))
    .environmentObject(AppCoordinator())
}

#Preview("리스트 - 읽고 있는") {
    let vm = LibraryTabViewModel(repository: .populated())
    vm.layoutStyle = .list
    vm.selectedFilter = .reading
    return LibraryTabView(viewModel: vm)
        .environmentObject(AppCoordinator())
}

#Preview("Empty State - 전체") {
    LibraryTabView(viewModel: LibraryTabViewModel(
        repository: .empty()
    ))
    .environmentObject(AppCoordinator())
}
```

---

## 6. 데이터 흐름

```
LibraryTabView.onAppear
    → viewModel.loadBooks()
        → repository.fetchAll() or fetchBy(status:)
        → books 정렬 적용
        → @Published books 업데이트
            → View 재렌더링

필터 탭 탭 시
    → viewModel.selectFilter(_:)
        → selectedFilter 업데이트
        → loadBooks() 재호출

[책 보러 가기] 탭 (Empty State)
    → coordinator.switchTab(to: .search)
```

**실시간 반영 전략:**
- 현재 단계에서는 `onAppear` + 명시적 reload로 처리
- `06-library-detail`에서 상태 변경 후 돌아올 때 `NavigationStack.onAppear` 트리거로 재로드
- SwiftData `@Query` 기반 실시간 반영은 `04-reading-tab` 구현 시 패턴 결정 후 적용

---

## 7. 네비게이션

```swift
// LibraryTabView 내부
NavigationStack {
    // ... content
    .navigationTitle("서재")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
            // 설정 버튼 (gear)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            // 레이아웃 전환 Menu
        }
    }
}
```

카드 탭 → `06-library-detail` 연결:
```swift
NavigationLink(value: book) {
    LibraryBookGridCard(book: book)   // or LibraryBookListRow
}
.navigationDestination(for: LibraryBook.self) { book in
    // 플레이스홀더 (03-book-detail, 06-library-detail 개발 후 교체)
    LibraryDetailPlaceholderView(book: book)
}
```

---

## 8. 에러 처리

```swift
func loadBooks() async {
    isLoading = true
    defer { isLoading = false }
    do {
        let fetched = selectedFilter == nil
            ? try repository.fetchAll()
            : try repository.fetchBy(status: selectedFilter!)
        books = sortedBooks(fetched)
    } catch {
        logger.error("서재 로드 실패: \(error.localizedDescription)")
        errorMessage = "서재를 불러오지 못했습니다."
    }
}
```

---

## 9. 작업 파일 목록

| 파일 경로 | 설명 |
|---|---|
| `UI/Library/LibraryTabView.swift` | 탭 루트 뷰 (기존 플레이스홀더 교체) |
| `UI/Library/LibraryTabViewModel.swift` | 필터·레이아웃 상태 + 데이터 로드 |
| `UI/Library/LibraryLayoutStyle.swift` | `enum LibraryLayoutStyle` |
| `UI/Library/Components/LibraryFilterTabView.swift` | 수평 필터 탭 컴포넌트 |
| `UI/Library/Components/LibraryBookGridCard.swift` | 그리드 카드 (표지만) |
| `UI/Library/Components/LibraryBookListRow.swift` | 리스트 행 (표지+제목+저자) |
| `UI/Library/Components/LibraryEmptyView.swift` | 탭별 Empty State |
| `UI/Library/Preview/LibraryBook+Preview.swift` | 더미 데이터 + Preview 구성 |
| `UI/Settings/SettingsPlaceholderView.swift` | 설정 화면 플레이스홀더 |

---

## 10. 완료 기준

- [ ] 4개 필터 탭이 동작하고 각 상태의 책이 올바르게 표시됨
- [ ] 그리드 ↔ 리스트 드롭다운 전환이 동작하고 선택값이 유지됨
- [ ] 그리드: 표지만, 리스트: 표지 + 제목 + 저자 레이아웃 정상 표시
- [ ] 각 필터의 Empty State가 올바른 메시지와 함께 표시됨
- [ ] 전체 Empty State의 [책 보러 가기]가 검색 탭으로 전환함
- [ ] NavigationBar 우측 설정(gear) 버튼이 플레이스홀더 설정 화면으로 이동
- [ ] coverURL 빈 경우 fallback 이미지 표시
- [ ] Preview 3종 (그리드/리스트/Empty)에서 더미 데이터가 정상 표시됨

---

## 11. 제약 사항

- 카드 탭 → 상세 화면은 `03-book-detail` / `06-library-detail` 개발 전까지 플레이스홀더 유지
- 이미지는 URL만 저장 (`LibraryBook.coverURL`), 캐싱은 `AsyncImage` 기본 동작에 의존
- 리스트 정렬에서 `.reading` 탭의 "최근 세션 기준 정렬"은 `LibraryBook.sessions`를 활용하되, 세션 데이터가 없는 현 단계에서는 `startedAt` 내림차순으로 폴백
- 설정 화면 구현은 Phase 3 스코프
