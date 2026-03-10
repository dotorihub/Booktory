# SRS — 책 상세 화면

> Phase 1 — `03-book-detail` 구현 기술 명세

---

## 1. 개요

검색 결과 리스트에서 책 아이템을 탭했을 때 push navigation으로 진입하는 상세 화면.
책의 메타 정보를 표시하고, [바로 읽기] / [읽고 싶은 책에 저장] 두 CTA를 통해 서재 등록의 진입점이 된다.

**의존**: `srs/data-layer.md`, `srs/library-action.md` (`01-library-action`)

---

## 2. 컴포넌트 구조

```
BookDetailView                          ← 상세 화면 루트 (NavigationStack child)
├── AsyncImage                          ← 책 표지 (상단 중앙)
├── 제목 / 저자 · 출판사 텍스트 블록
├── Divider
├── DescriptionView                     ← 책 소개 + 더 보기 토글
└── ActionButtonsView                   ← 하단 CTA 버튼 영역
    ├── [읽고 싶은 책에 저장] 버튼       ← 보조 버튼 (outline)
    └── [바로 읽기] 버튼                 ← 주요 버튼 (filled)
```

---

## 3. ViewModel 설계

### `BookDetailViewModel`

```swift
@MainActor
final class BookDetailViewModel: ObservableObject {

    // MARK: - 서재 상태

    enum LibraryState: Equatable {
        case notInLibrary
        case wantToRead(id: UUID)
        case reading(id: UUID)
        case completed(id: UUID)
    }

    // MARK: - 책 소개 토글 상태

    @Published private(set) var libraryState: LibraryState = .notInLibrary
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isDescriptionExpanded: Bool = false

    private let book: Book
    private let repository: any LibraryRepositoryProtocol
    private let coordinator: AppCoordinator

    init(book: Book,
         repository: any LibraryRepositoryProtocol,
         coordinator: AppCoordinator)

    // MARK: - 공개 인터페이스

    func loadLibraryState() async
    func readNow() async
    func saveToWishlist() async
    func removeFromWishlist() async
}
```

### 상태 → UI 매핑

| `LibraryState` | [바로 읽기] 버튼 | [읽고 싶은 책에 저장] 버튼 |
|---|---|---|
| `.notInLibrary` | 활성 / "바로 읽기" | 활성 / `bookmark` 아이콘 |
| `.wantToRead` | 활성 / "바로 읽기" | 활성 / `bookmark.fill` 아이콘 (탭 시 제거) |
| `.reading` | 비활성 / "읽고 있는 중" | 숨김 |
| `.completed` | 비활성 / "완독한 책" | 숨김 |

---

## 4. UI 명세

### 4-1. 전체 레이아웃

```
┌─────────────────────────────┐
│  < 뒤로가기                  │  ← NavigationBar (inline title 없음)
├─────────────────────────────┤
│  ScrollView                  │
│  ┌───────────────────────┐  │
│  │     [책 표지 이미지]    │  │  ← AsyncImage, 중앙 정렬, 최대 너비 200pt
│  └───────────────────────┘  │
│                             │
│  제목                        │  ← .title2, bold, multiline, center
│  저자 · 출판사               │  ← .subheadline, secondary, center
│                             │
│  ─────────────────────────  │  ← Divider
│                             │
│  책 소개                     │  ← 기본 4줄 제한
│  [더 보기 ▼] / [접기 ▲]     │  ← 토글 버튼 (소개 짧으면 미표시)
│                             │
└─────────────────────────────┘
│  [읽고 싶은 책에 저장]        │  ← 하단 고정 영역 (safeArea 위)
│  [바로 읽기]                 │
└─────────────────────────────┘
```

### 4-2. 책 표지 AsyncImage

```swift
AsyncImage(url: URL(string: book.coverURL)) { phase in
    switch phase {
    case .success(let image):
        image
            .resizable()
            .scaledToFit()
    case .failure:
        Image(systemName: "book.closed.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.quaternary)
    case .empty:
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
    @unknown default:
        EmptyView()
    }
}
.frame(maxWidth: 200)
.aspectRatio(contentMode: .fit)
.cornerRadius(8)
.shadow(radius: 4)
```

### 4-3. 책 소개 더 보기 토글

- 기본: `lineLimit(4)` 적용
- "더 보기" 버튼 탭 시 `isDescriptionExpanded = true` → `lineLimit(nil)`
- "접기" 버튼 탭 시 `isDescriptionExpanded = false` → `lineLimit(4)`
- `description`이 4줄 이하이면 버튼 미표시 (`ViewThatFits` 또는 `background` GeometryReader로 판별)

```swift
// description 길이 판단 전략
// Text의 실제 렌더 높이(4줄 제한)와 제한 없는 높이를 비교해 isLong 판단
@State private var isDescriptionLong: Bool = false
```

### 4-4. 액션 버튼 영역 (하단 고정)

두 버튼을 `HStack`으로 나란히 배치한다.

- **[읽고 싶은 책] 버튼**: 아이콘(`bookmark` / `bookmark.fill`)만 표시, 1:1 정사각형, `.bordered` 스타일, rounded
- **[바로 읽기] 버튼**: 나머지 너비를 모두 차지 (`maxWidth: .infinity`), `.borderedProminent` 스타일, rounded

```
┌────────┬────────────────────────────┐
│  [🔖]  │        바로 읽기           │  ← HStack
└────────┴────────────────────────────┘
 1:1 고정          나머지 전체 너비
```

```swift
HStack(spacing: 12) {
    // 읽고 싶은 책 버튼: 아이콘 전용, 1:1 정사각형
    // .notInLibrary, .wantToRead 상태일 때만 표시
    if viewModel.showWishlistButton {
        Button { Task { await viewModel.toggleWishlist() } } label: {
            Image(systemName: viewModel.wishlistIconName)
                .imageScale(.large)
        }
        .buttonStyle(.bordered)
        .tint(.primary)
        .aspectRatio(1, contentMode: .fit)   // 1:1 정사각형 유지
        .accessibilityLabel(viewModel.wishlistAccessibilityLabel)
    }

    // 바로 읽기 버튼: 나머지 너비 전체 차지
    Button { Task { await viewModel.readNow() } } label: {
        Text(viewModel.readNowButtonLabel)
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .disabled(!viewModel.isReadNowEnabled)
}
.padding()
.background(.regularMaterial)
```

**아이콘 규칙**

| `LibraryState` | `wishlistIconName` |
|---|---|
| `.notInLibrary` | `"bookmark"` |
| `.wantToRead` | `"bookmark.fill"` |

---

## 5. ViewModel 연산 프로퍼티

```swift
extension BookDetailViewModel {

    /// [바로 읽기] 버튼 레이블
    var readNowButtonLabel: String {
        switch libraryState {
        case .notInLibrary, .wantToRead: return "바로 읽기"
        case .reading:                   return "읽고 있는 중"
        case .completed:                 return "완독한 책"
        }
    }

    /// [바로 읽기] 활성 여부
    var isReadNowEnabled: Bool {
        switch libraryState {
        case .notInLibrary, .wantToRead, .reading: return true
        case .completed:                            return false
        }
    }

    /// [읽고 싶은 책] 버튼 표시 여부
    var showWishlistButton: Bool {
        switch libraryState {
        case .notInLibrary, .wantToRead: return true
        case .reading, .completed:       return false
        }
    }

    /// [읽고 싶은 책] 버튼 아이콘 이름
    var wishlistIconName: String {
        switch libraryState {
        case .notInLibrary: return "bookmark"
        case .wantToRead:   return "bookmark.fill"
        default:            return "bookmark"
        }
    }

    /// [읽고 싶은 책] 버튼 접근성 레이블 (VoiceOver)
    var wishlistAccessibilityLabel: String {
        switch libraryState {
        case .notInLibrary: return "읽고 싶은 책에 저장"
        case .wantToRead:   return "저장됨, 탭하면 제거"
        default:            return ""
        }
    }

    /// 위시리스트 토글: 없으면 저장, 있으면 제거
    func toggleWishlist() async {
        switch libraryState {
        case .notInLibrary: await saveToWishlist()
        case .wantToRead:   await removeFromWishlist()
        default: break
        }
    }
}
```

---

## 6. 비즈니스 로직

비즈니스 로직 상세는 `srs/library-action.md` 섹션 2–7을 따른다.
본 SRS에서는 `BookDetailViewModel`이 호출하는 흐름만 정리한다.

### 화면 진입 시

```
BookDetailView.task
  → viewModel.loadLibraryState()
      → repository.fetchBy(isbn: book.id)
      → libraryState 업데이트
```

### [바로 읽기] 탭

```
viewModel.readNow()
  → library-action.md §2-1 흐름 실행
  → coordinator.openTimer(for: bookId)
```

### [읽고 싶은 책에 저장] 탭

```
viewModel.saveToWishlist()   // libraryState == .notInLibrary
  → library-action.md §2-2 흐름 실행
  → libraryState = .wantToRead(id: ...)

viewModel.removeFromWishlist()  // libraryState == .wantToRead (토글)
  → library-action.md §2-3 흐름 실행
  → libraryState = .notInLibrary
```

---

## 7. 네비게이션 연결

### SearchView → BookDetailView

```swift
// SearchView 내부 (NavigationStack 하위)
NavigationLink(value: book) {
    BookSearchRow(book: book)
}
.navigationDestination(for: Book.self) { book in
    BookDetailView(
        viewModel: BookDetailViewModel(
            book: book,
            repository: repository,
            coordinator: coordinator
        )
    )
}
```

> `Book`이 `Hashable`을 준수해야 `NavigationLink(value:)` 사용 가능.
> `Book` 모델에 `Hashable` 채택 추가 필요.

### NavigationStack 구성

- `SearchView`가 이미 `NavigationStack` 내부에 있다면 `navigationDestination`만 추가
- 현재 `SearchView` 구조 확인 후 적용 위치 결정

---

## 8. 데이터 모델 요구사항

### Book (기존 모델 수정)

```swift
// BookModels.swift에 Hashable 채택 추가
struct Book: Identifiable, Hashable {
    let id: String          // ISBN
    let title: String
    let author: String
    let publisher: String
    let coverURL: String
    let description: String
}
```

### 입출력 요약

| 항목 | 내용 |
|---|---|
| 입력 | `Book` (SearchView에서 전달) |
| 읽기 | `repository.fetchBy(isbn:)` — 서재 존재 여부 |
| 쓰기 | `repository.add(_:)`, `repository.updateStatus(id:to:)`, `repository.delete(id:)` |

---

## 9. 에러 처리

`library-action.md §7`의 에러 처리 원칙을 동일하게 적용한다.

```swift
// errorMessage가 nil이 아닐 때 Alert 표시
.alert("오류", isPresented: $viewModel.showErrorAlert) {
    Button("확인", role: .cancel) { }
} message: {
    Text(viewModel.errorMessage ?? "")
}
```

| 에러 종류 | 처리 |
|---|---|
| `duplicateISBN` | 무시 + 상태 재로드 |
| `bookNotFound` | `logger.error` + `errorMessage` 설정 |
| 기타 DB 오류 | 한국어 Alert 표시 |

---

## 10. Preview 전략

```swift
// BookDetailView.swift 하단

#Preview("서재에 없는 책") {
    NavigationStack {
        BookDetailView(viewModel: BookDetailViewModel(
            book: .preview,
            repository: PreviewLibraryRepository.empty(),
            coordinator: AppCoordinator()
        ))
    }
}

#Preview("읽고 싶은 책") {
    let repo = PreviewLibraryRepository.empty()
    let book = Book.preview
    try? repo.add(LibraryBook(from: book, status: .wantToRead))
    return NavigationStack {
        BookDetailView(viewModel: BookDetailViewModel(
            book: book,
            repository: repo,
            coordinator: AppCoordinator()
        ))
    }
}

#Preview("읽고 있는 책") {
    let repo = PreviewLibraryRepository.empty()
    let book = Book.preview
    try? repo.add(LibraryBook(from: book, status: .reading))
    return NavigationStack {
        BookDetailView(viewModel: BookDetailViewModel(
            book: book,
            repository: repo,
            coordinator: AppCoordinator()
        ))
    }
}
```

```swift
// BookModels.swift 또는 Preview Content
extension Book {
    static let preview = Book(
        id: "9791162540145",
        title: "클린 코드",
        author: "로버트 C. 마틴",
        publisher: "인사이트",
        coverURL: "",
        description: "애자일 소프트웨어 장인 정신을 담은 책. 좋은 코드를 작성하는 방법과 나쁜 코드를 좋은 코드로 바꾸는 방법을 상세히 설명한다. 단순히 작동하는 코드를 넘어서 읽기 쉽고 유지보수하기 좋은 코드를 만드는 원칙과 패턴을 다룬다."
    )
}
```

---

## 11. 작업 파일 목록

| 파일 경로 | 설명 |
|---|---|
| `UI/Search/BookDetailView.swift` | 책 상세 화면 루트 뷰 |
| `UI/Search/BookDetailViewModel.swift` | 상세 화면 ViewModel |
| `Networking/Model/BookModels.swift` | `Book`에 `Hashable` 채택 추가 |
| `UI/Search/SearchView.swift` | `NavigationLink(value:)` + `navigationDestination` 추가 |

> `BookDetailView`는 Search 탭에서 진입하므로 `UI/Search/` 하위에 배치한다.
> 추후 서재 탭(`06-library-detail`)에서도 별도 경로로 진입하므로, 공용 컴포넌트는 `UI/Components/`로 이동 가능성 열어둠.

---

## 12. 완료 기준

- [ ] 검색 결과 아이템 탭 시 상세 화면으로 push 이동
- [ ] 책 정보(표지 / 제목 / 저자 / 출판사 / 소개)가 정상 표시됨
- [ ] 표지 이미지 로딩 실패 시 fallback SF Symbol 표시
- [ ] 소개가 긴 책은 기본 4줄 + "더 보기" / "접기" 토글 동작
- [ ] 소개가 짧은 책은 "더 보기" 버튼 미표시
- [ ] 서재에 없는 책: 두 버튼 모두 활성
- [ ] `.wantToRead` 책: [바로 읽기] 활성, [저장됨] 토글 동작
- [ ] `.reading` 책: [읽고 있는 중] 비활성, [읽고 싶은 책] 버튼 숨김
- [ ] `.completed` 책: [완독한 책] 비활성, [읽고 싶은 책] 버튼 숨김
- [ ] [바로 읽기] 탭 시 독서 탭 전환 + 타이머 자동 오픈
- [ ] Preview 3종 (서재 없음 / wantToRead / reading) 정상 표시

---

## 13. 제약 사항

- `Book` 모델은 네트워크 캐시 없이 SearchView에서 전달된 인스턴스를 그대로 사용
- 표지 이미지 캐싱은 `AsyncImage` 기본 동작에 의존 (별도 캐시 레이어 불필요)
- "다시 읽기" (`.completed` 상태) 는 Phase 3 스코프 — 현재 버튼 비활성 처리
- 위시리스트 삭제 확인 팝업 없음 (즉시 삭제)
- 탭 전환은 반드시 `AppCoordinator.openTimer(for:)` / `switchTab(to:)`를 통해서만 수행
