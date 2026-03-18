# SRS — 서재 책 상세 + 세션 히스토리

> Phase 1 — `06-library-detail` 구현 기술 명세

---

## 1. 개요

서재 탭(`LibraryTabView`)에서 책 카드를 탭했을 때 진입하는 상세 화면.
해당 `LibraryBook`의 메타 정보, 독서 통계, 세션 히스토리를 보여주고,
상태 변경(완독 처리, 읽기 시작)과 삭제 액션을 제공한다.

**의존**: `srs/data-layer.md`, `srs/timer-session.md`

**현재 상태**: `LibraryTabView`에 `NavigationLink(value: book)`은 존재하지만
`.navigationDestination(for: LibraryBook.self)` 핸들러가 없어 상세 화면으로의 네비게이션이 연결되지 않은 상태.

---

## 2. 컴포넌트 구조

```
LibraryTabContentView
└── NavigationStack
    └── .navigationDestination(for: LibraryBook.self)
        └── LibraryDetailView (진입점)
            └── LibraryDetailContentView
                ├── 책 정보 헤더 (표지, 제목, 저자, 출판사)
                ├── 독서 통계 섹션 (총 시간, 횟수, 날짜 정보)
                ├── 책 소개 (ExpandableDescriptionView 재사용)
                ├── 세션 히스토리 리스트 (SessionHistorySection)
                │   ├── [세션 있음] SessionRow × N
                │   └── [세션 없음] 빈 상태 메시지
                └── 상태 액션 버튼 (하단 고정)
```

---

## 3. ViewModel 설계

### `LibraryDetailViewModel`

```swift
@MainActor
final class LibraryDetailViewModel: ObservableObject {

    // MARK: - 상태

    @Published private(set) var book: LibraryBook
    @Published private(set) var sessions: [ReadingSession] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    /// 삭제 확인 Alert 트리거
    @Published var showDeleteConfirm: Bool = false

    /// 삭제 완료 후 이전 화면으로 pop 트리거
    @Published var shouldDismiss: Bool = false

    private let repository: any LibraryRepositoryProtocol
    private let logger = Logger(subsystem: "com.booktory", category: "LibraryDetail")

    init(book: LibraryBook, repository: any LibraryRepositoryProtocol) {
        self.book = book
        self.repository = repository
    }
}
```

### 공개 인터페이스

```swift
extension LibraryDetailViewModel {

    /// 화면 진입 시 세션 목록 로드
    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        do {
            sessions = try repository.fetchSessions(for: book.id)
        } catch {
            logger.error("세션 로드 실패: \(error.localizedDescription)")
            errorMessage = "독서 기록을 불러오지 못했습니다."
        }
    }

    /// 상태 변경: wantToRead → reading
    func startReading() async {
        do {
            try repository.updateStatus(id: book.id, to: .reading)
            book.status = .reading
            book.startedAt = book.startedAt ?? Date()
        } catch {
            logger.error("상태 변경 실패: \(error.localizedDescription)")
            errorMessage = "상태를 변경하지 못했습니다."
        }
    }

    /// 상태 변경: reading → completed
    func markAsCompleted() async {
        do {
            try repository.updateStatus(id: book.id, to: .completed)
            book.status = .completed
            book.completedAt = Date()
        } catch {
            logger.error("완독 처리 실패: \(error.localizedDescription)")
            errorMessage = "완독 처리에 실패했습니다."
        }
    }

    /// 서재에서 삭제
    func deleteBook() async {
        do {
            try repository.delete(id: book.id)
            shouldDismiss = true
        } catch {
            logger.error("삭제 실패: \(error.localizedDescription)")
            errorMessage = "삭제에 실패했습니다."
        }
    }
}
```

### 계산 프로퍼티

```swift
extension LibraryDetailViewModel {

    /// 총 독서 시간 (초)
    var totalReadingSeconds: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    /// 총 독서 횟수
    var sessionCount: Int {
        sessions.count
    }

    /// 총 독서 시간 포맷 ("3시간 20분" / "45분" / "0분")
    var formattedTotalTime: String {
        let total = Int(totalReadingSeconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }
        return "\(minutes)분"
    }

    /// 서재 추가일 포맷
    var formattedAddedAt: String {
        book.addedAt.formatted(date: .abbreviated, time: .omitted)
    }

    /// 독서 시작일 포맷 (nil이면 "-")
    var formattedStartedAt: String {
        book.startedAt?.formatted(date: .abbreviated, time: .omitted) ?? "-"
    }

    /// 완독일 포맷 (nil이면 "-")
    var formattedCompletedAt: String {
        book.completedAt?.formatted(date: .abbreviated, time: .omitted) ?? "-"
    }
}
```

---

## 4. View 설계

### `LibraryDetailView` (진입점)

기존 `BookDetailView` 패턴을 따른다. 환경에서 repository를 읽어 ViewModel을 생성.

```swift
struct LibraryDetailView: View {
    let book: LibraryBook
    @Environment(\.libraryRepository) private var repository

    var body: some View {
        LibraryDetailContentView(
            viewModel: LibraryDetailViewModel(book: book, repository: repository)
        )
    }
}
```

### `LibraryDetailContentView` 레이아웃

```swift
private struct LibraryDetailContentView: View {
    @StateObject var viewModel: LibraryDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                coverImage         // 표지 이미지
                bookInfo           // 제목, 저자 · 출판사
                Divider()
                statsSection       // 독서 통계 (총 시간, 횟수, 날짜)
                Divider()
                descriptionSection // 책 소개 (ExpandableDescriptionView 재사용)
                sessionHistory     // 세션 히스토리
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { deleteToolbarItem }
        .safeAreaInset(edge: .bottom) { actionButton }
        .task { await viewModel.loadSessions() }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        // 삭제 확인 Alert
        // 에러 Alert
    }
}
```

### 독서 통계 섹션

```
┌─────────────────────────────┐
│  총 독서 시간     독서 횟수   │
│   3시간 20분        8회      │
├─────────────────────────────┤
│  추가일     시작일    완독일   │
│  3.1        2.28      -     │
└─────────────────────────────┘
```

```swift
private var statsSection: some View {
    VStack(spacing: 16) {
        // 상단: 총 독서 시간 + 횟수
        HStack {
            StatItem(title: "총 독서 시간", value: viewModel.formattedTotalTime)
            Divider().frame(height: 40)
            StatItem(title: "독서 횟수", value: "\(viewModel.sessionCount)회")
        }

        // 하단: 날짜 정보
        HStack {
            StatItem(title: "추가일", value: viewModel.formattedAddedAt)
            if viewModel.book.status != .wantToRead {
                StatItem(title: "시작일", value: viewModel.formattedStartedAt)
            }
            if viewModel.book.status == .completed {
                StatItem(title: "완독일", value: viewModel.formattedCompletedAt)
            }
        }
    }
    .padding(.horizontal)
}
```

`StatItem`은 간단한 내부 뷰로, title(캡션) + value(본문) 세로 배치.

### 세션 히스토리 섹션

```swift
private var sessionHistory: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("독서 기록")
            .font(.headline)
            .padding(.horizontal)

        if viewModel.sessions.isEmpty {
            // 빈 상태
            Text("아직 독서 기록이 없어요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else {
            // 세션 리스트 (최신순, repository에서 이미 정렬됨)
            ForEach(viewModel.sessions, id: \.id) { session in
                SessionRow(session: session)
            }
        }
    }
}
```

### `SessionRow`

각 세션을 한 줄로 표시. 날짜 + 독서 시간.

```swift
private struct SessionRow: View {
    let session: ReadingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // 날짜: "2025.03.01"
                Text(session.startTime.formatted(
                    .dateTime.year().month(.twoDigits).day(.twoDigits)
                ))
                .font(.subheadline)

                // 시작 시간: "오후 2:30"
                Text(session.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 독서 시간: "40분" / "1시간 05분"
            Text(formattedDuration(session.duration))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(String(format: "%02d", minutes))분"
        }
        return "\(minutes)분"
    }
}
```

### 상태 액션 버튼 (하단 고정)

현재 `ReadingStatus`에 따라 다른 버튼을 표시:

```swift
@ViewBuilder
private var actionButton: some View {
    switch viewModel.book.status {
    case .wantToRead:
        // [읽기 시작] → reading 전환
        bottomButton(label: "읽기 시작", color: .green) {
            Task { await viewModel.startReading() }
        }
    case .reading:
        // [완독으로 표시] → completed 전환
        bottomButton(label: "완독으로 표시", color: .accentColor) {
            Task { await viewModel.markAsCompleted() }
        }
    case .completed:
        // 완독 상태 — 액션 버튼 없음 (또는 비활성 "완독" 뱃지)
        EmptyView()
    }
}
```

### 삭제 기능

Toolbar에 더보기 메뉴로 삭제 옵션을 제공:

```swift
@ToolbarContentBuilder
private var deleteToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
            Button(role: .destructive) {
                viewModel.showDeleteConfirm = true
            } label: {
                Label("서재에서 삭제", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .accessibilityLabel("더보기")
        }
    }
}
```

삭제 확인 Alert:

```swift
.alert("서재에서 삭제", isPresented: $viewModel.showDeleteConfirm) {
    Button("취소", role: .cancel) {}
    Button("삭제", role: .destructive) {
        Task { await viewModel.deleteBook() }
    }
} message: {
    Text("서재에서 삭제하면 모든 독서 기록도 함께 삭제됩니다.")
}
```

---

## 5. LibraryTabView 연동

`LibraryTabContentView`의 `NavigationStack`에 `.navigationDestination` 추가:

```swift
// LibraryTabContentView body 내부, NavigationStack 하위에 추가
.navigationDestination(for: LibraryBook.self) { book in
    LibraryDetailView(book: book)
}
```

> `LibraryBook`은 `@Model`이므로 `Hashable`을 자동 준수한다.
> 기존 `NavigationLink(value: book)` 코드와 연결된다.

---

## 6. 재사용 컴포넌트

| 컴포넌트 | 출처 | 용도 |
|---|---|---|
| `ExpandableDescriptionView` | `BookDetailView.swift` (private) | 책 소개 더보기/접기 |

`ExpandableDescriptionView`는 현재 `BookDetailView.swift` 내부에 `private`으로 선언되어 있다.
`LibraryDetailView`에서도 사용해야 하므로 `UI/Components/ExpandableDescriptionView.swift`로 추출한다.

---

## 7. 파일 구조

```
Booktory/UI/Library/
├── LibraryTabView.swift              ← 수정 (navigationDestination 추가)
├── LibraryTabViewModel.swift
├── LibraryLayoutStyle.swift
├── LibraryDetailView.swift           ← 신규
├── LibraryDetailViewModel.swift      ← 신규
├── Components/
│   ├── LibraryBookGridCard.swift
│   ├── LibraryBookListRow.swift
│   ├── LibraryFilterTabView.swift
│   └── LibraryEmptyView.swift
└── Preview/
    └── LibraryBook+Preview.swift

Booktory/UI/Components/
└── ExpandableDescriptionView.swift   ← BookDetailView에서 추출
```

---

## 8. 엣지 케이스

| 상황 | 처리 |
|---|---|
| 세션이 없는 책 | 히스토리 섹션에 "아직 독서 기록이 없어요" 메시지 |
| wantToRead 상태 | 통계에 시작일/완독일 미표시, [읽기 시작] 버튼 |
| completed 상태 | 완독일 표시, 하단 액션 버튼 없음 |
| 삭제 후 | `shouldDismiss = true` → dismiss → 서재 탭 목록 자동 갱신 |
| 상태 변경 실패 | 에러 Alert, 기존 상태 유지 |
| 삭제 실패 | 에러 Alert, 화면 유지 |

---

## 9. 작업 목록

### 1. ExpandableDescriptionView 추출
- [ ] `BookDetailView.swift`에서 `ExpandableDescriptionView` + `TruncationPreferenceKey`를 `UI/Components/`로 이동
- [ ] `BookDetailView`에서 import 확인

### 2. LibraryDetailViewModel 생성
- [ ] `LibraryDetailViewModel.swift` 생성 (`@MainActor ObservableObject`)
- [ ] 세션 로드 (`loadSessions`)
- [ ] 계산 프로퍼티 (총 시간, 횟수, 날짜 포맷)
- [ ] 상태 변경 (`startReading`, `markAsCompleted`)
- [ ] 삭제 (`deleteBook`) + 삭제 확인 Alert 트리거
- [ ] `shouldDismiss` 플래그

### 3. LibraryDetailView 생성
- [ ] 진입점 뷰 (환경에서 repository 주입)
- [ ] 책 정보 헤더 (표지, 제목, 저자, 출판사)
- [ ] 독서 통계 섹션 (총 시간, 횟수, 날짜)
- [ ] 책 소개 (`ExpandableDescriptionView`)
- [ ] 세션 히스토리 섹션 + `SessionRow`
- [ ] 상태별 액션 버튼 (하단 고정)
- [ ] Toolbar 더보기 메뉴 (삭제)
- [ ] 삭제 확인 Alert
- [ ] 에러 Alert
- [ ] Preview 작성

### 4. LibraryTabView 연동
- [ ] `.navigationDestination(for: LibraryBook.self)` 추가

---

## 10. 완료 기준

- [ ] 서재 탭에서 책 카드 탭 시 상세 화면으로 네비게이션됨
- [ ] 책 메타 정보(표지, 제목, 저자, 출판사)가 정확히 표시됨
- [ ] 독서 통계(총 시간, 횟수, 날짜)가 정확히 표시됨
- [ ] 세션 히스토리가 최신순으로 표시됨
- [ ] 세션이 없는 책은 빈 상태 메시지 표시
- [ ] [읽기 시작] 탭 시 wantToRead → reading 전환 반영
- [ ] [완독으로 표시] 탭 시 reading → completed 전환 반영
- [ ] 삭제 시 확인 Alert → 삭제 → 서재 탭으로 pop, 목록에서 제거
- [ ] 책 소개 더보기/접기 정상 동작
