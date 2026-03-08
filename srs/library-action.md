# SRS — 서재 액션 (바로읽기 / 읽고 싶은 책 저장)

> Phase 1 — `01-library-action` 구현 기술 명세

---

## 1. 개요

책 상세 화면의 두 CTA 버튼([바로 읽기], [읽고 싶은 책에 저장])에 대한 비즈니스 로직 명세.
Naver API 검색 결과(`Book`)를 서재(`LibraryBook`)로 전환하는 앱의 핵심 진입점이다.

**의존**: `srs/data-layer.md` (LibraryRepositoryProtocol, LibraryBook, ReadingStatus)

---

## 2. 액션 정의

### 2-1. 바로 읽기 (`readNow`)

| 항목 | 내용 |
|---|---|
| 트리거 | [바로 읽기] 버튼 탭 |
| 입력 | `Book` (Naver API 검색 모델) |
| 사이드이펙트 | 서재 저장 + 독서 탭 전환 + 타이머 자동 오픈 트리거 |

**처리 흐름:**

```
readNow(book: Book)
  │
  ├─ fetchBy(isbn:) 호출
  │
  ├─ [서재에 없음]
  │    LibraryBook(from: book, status: .reading) 생성
  │    repository.add(book) 호출
  │
  ├─ [서재에 있음, .wantToRead]
  │    repository.updateStatus(id:, to: .reading) 호출
  │
  ├─ [서재에 있음, .reading]
  │    상태 변경 없음 (탭 전환만)
  │
  ├─ [서재에 있음, .completed]
  │    이 분기에 도달하지 않음 (버튼 비활성)
  │
  └─ coordinator.openTimer(for: bookId)
       → coordinator.pendingAutoOpenBookId = bookId
       → coordinator.switchTab(to: .reading)
```

**상태 전이:**
```
[없음]       ──readNow──▶  reading
[wantToRead] ──readNow──▶  reading
[reading]    ──readNow──▶  reading (no-op, 탭 전환만)
[completed]  ──readNow──▶  (비활성, 액션 없음)
```

---

### 2-2. 읽고 싶은 책 저장 (`saveToWishlist`)

| 항목 | 내용 |
|---|---|
| 트리거 | [읽고 싶은 책에 저장] 버튼 탭 |
| 입력 | `Book` |
| 사이드이펙트 | 서재 저장 (탭 전환 없음) |

**처리 흐름:**

```
saveToWishlist(book: Book)
  │
  ├─ fetchBy(isbn:) 호출
  │
  ├─ [서재에 없음]
  │    LibraryBook(from: book, status: .wantToRead) 생성
  │    repository.add(book) 호출
  │
  └─ [서재에 있음]
       아무 변경 없음 (이미 저장된 상태로 UI 반영)
```

---

### 2-3. 위시리스트 제거 (`removeFromWishlist`)

| 항목 | 내용 |
|---|---|
| 트리거 | [저장됨] 버튼 재탭 (토글) |
| 입력 | `isbn: String` |
| 제약 | `.wantToRead` 상태일 때만 허용 |
| 사이드이펙트 | 서재에서 삭제 (확인 팝업 없음) |

---

## 3. ViewModel 설계

### `BookDetailViewModel`

```swift
@MainActor
final class BookDetailViewModel: ObservableObject {

    enum LibraryState: Equatable {
        case notInLibrary
        case wantToRead(id: UUID)
        case reading(id: UUID)
        case completed(id: UUID)
    }

    @Published private(set) var libraryState: LibraryState = .notInLibrary
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let book: Book
    private let repository: any LibraryRepositoryProtocol
    private let coordinator: AppCoordinator

    // MARK: - 공개 인터페이스
    func loadLibraryState() async
    func readNow() async
    func saveToWishlist() async
    func removeFromWishlist() async
}
```

### 상태 → UI 매핑

| `LibraryState` | [바로 읽기] 버튼 | [읽고 싶은 책] 버튼 |
|---|---|---|
| `.notInLibrary` | 활성 / "바로 읽기" | 활성 / "읽고 싶은 책에 저장" |
| `.wantToRead` | 활성 / "바로 읽기" | 활성 / "저장됨 ✕" (토글) |
| `.reading` | 비활성 / "읽고 있는 중" | 숨김 |
| `.completed` | 비활성 / "완독한 책" | 숨김 |

---

## 4. 탭 전환 및 타이머 자동 오픈 연동

`readNow` 완료 후 독서 탭으로 이동하고, 해당 책의 타이머를 자동 오픈한다.

### AppCoordinator 확장

```swift
// AppCoordinator에 추가
@Published var pendingAutoOpenBookId: UUID?

func openTimer(for bookId: UUID) {
    pendingAutoOpenBookId = bookId
    switchTab(to: .reading)
}
```

### 독서 탭에서의 소비

```swift
// ReadingTabView (또는 ReadingTabViewModel)
.onChange(of: coordinator.pendingAutoOpenBookId) { _, bookId in
    guard let bookId else { return }
    openTimerFullScreen(for: bookId)
    coordinator.pendingAutoOpenBookId = nil  // 소비 후 반드시 초기화
}
```

---

## 5. Book → LibraryBook 변환

```swift
extension LibraryBook {
    /// Naver API 검색 결과(Book)를 서재 모델로 변환한다.
    convenience init(from book: Book, status: ReadingStatus) {
        self.init(
            isbn: book.id,                  // Book.id == Naver ISBN
            title: book.title,
            author: book.author,
            publisher: book.publisher,
            coverURL: book.coverURL,
            bookDescription: book.description,
            status: status
        )
        // startedAt은 LibraryBook.init에서 status == .reading이면 자동 설정
    }
}
```

저장 시점의 필드 초기값:

| 필드 | `wantToRead`로 저장 | `reading`으로 저장 |
|---|---|---|
| `addedAt` | `Date()` | `Date()` |
| `startedAt` | `nil` | `Date()` |
| `completedAt` | `nil` | `nil` |

---

## 6. 중복 추가 방지

- **기준 키**: `Book.id` (== Naver API의 ISBN 문자열)
- `add(_:)` 호출 전 `fetchBy(isbn:)` 선확인 (ViewModel 레벨)
- `DefaultLibraryRepository.add(_:)`도 내부에서 중복 체크 후 `LibraryRepositoryError.duplicateISBN` 반환 (이중 방어)
- 중복 감지 시 에러 무시 후 현재 상태 재로드

---

## 7. 에러 처리

```swift
do {
    try repository.add(libraryBook)
} catch LibraryRepositoryError.duplicateISBN {
    // 중복은 정상 경로 — 현재 상태만 재로드
    await loadLibraryState()
} catch {
    logger.error("서재 저장 실패: \(error.localizedDescription)")
    errorMessage = "서재에 저장하지 못했습니다. 다시 시도해 주세요."
}
```

| 에러 종류 | 처리 |
|---|---|
| `duplicateISBN` | 무시 + 상태 재로드 |
| `bookNotFound` | `logger.error` + `errorMessage` 설정 |
| 기타 DB 오류 | 한국어 Alert 표시 |

---

## 8. 테스트 시나리오

| 시나리오 | 전제 | 기대 결과 |
|---|---|---|
| 새 책 바로 읽기 | 서재에 없음 | `reading`으로 추가 + 독서 탭 전환 + 타이머 트리거 |
| 위시리스트 책 바로 읽기 | `.wantToRead` 존재 | `reading`으로 상태 변경 + 독서 탭 전환 |
| 읽고 있는 책 바로 읽기 탭 | `.reading` 존재 | 상태 변경 없음 + 독서 탭 전환만 |
| 완독 책 바로 읽기 버튼 | `.completed` 존재 | 버튼 비활성 (액션 없음) |
| 새 책 위시리스트 저장 | 서재에 없음 | `wantToRead`로 추가 |
| 위시리스트 토글(삭제) | `.wantToRead` 존재 | 서재에서 삭제 |
| 동일 ISBN 중복 저장 | 이미 존재 | 에러 없이 현재 상태 유지 |
| DB 오류 | 저장 중 예외 | 한국어 Alert 표시 |

---

## 9. 제약 사항

- `completed` 책의 "다시 읽기"는 **Phase 3** 스코프 (현재 버튼 비활성 처리)
- 위시리스트 토글 삭제는 세션 데이터가 없는 `.wantToRead` 책에만 적용
- 탭 전환은 반드시 `AppCoordinator.switchTab(to:)` / `openTimer(for:)`를 통해서만 수행
- 1분 미만 세션은 저장하지 않는 규칙은 `05-timer-session` 스코프
