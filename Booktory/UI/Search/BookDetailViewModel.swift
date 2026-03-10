//
//  BookDetailViewModel.swift
//  Booktory
//

import Foundation
import Combine
import OSLog

private let logger = Logger(subsystem: "com.dotorihub.Booktory", category: "BookDetail")

@MainActor
final class BookDetailViewModel: ObservableObject {

    // MARK: - 서재 상태

    enum LibraryState: Equatable {
        case notInLibrary
        case wantToRead(id: UUID)
        case reading(id: UUID)
        case completed(id: UUID)
    }

    // MARK: - Published

    @Published private(set) var libraryState: LibraryState = .notInLibrary
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Properties

    let book: Book

    private let repository: any LibraryRepositoryProtocol
    private let coordinator: AppCoordinator

    // MARK: - Init

    init(book: Book,
         repository: any LibraryRepositoryProtocol,
         coordinator: AppCoordinator) {
        self.book = book
        self.repository = repository
        self.coordinator = coordinator
    }

    // MARK: - 공개 인터페이스

    func loadLibraryState() async {
        do {
            let found = try repository.fetchBy(isbn: book.id)
            libraryState = makeLibraryState(from: found)
        } catch {
            logger.error("서재 상태 로드 실패: \(error.localizedDescription)")
        }
    }

    func readNow() async {
        guard isReadNowEnabled else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let existing = try repository.fetchBy(isbn: book.id)
            let bookId: UUID

            switch existing {
            case .none:
                let newBook = LibraryBook(from: book, status: .reading)
                try repository.add(newBook)
                bookId = newBook.id
                libraryState = .reading(id: bookId)

            case .some(let lib) where lib.status == .wantToRead:
                try repository.updateStatus(id: lib.id, to: .reading)
                bookId = lib.id
                libraryState = .reading(id: bookId)

            case .some(let lib):
                // .reading — 상태 변경 없이 탭 전환만
                bookId = lib.id
            }

            coordinator.openTimer(for: bookId)
        } catch LibraryRepositoryError.duplicateISBN {
            await loadLibraryState()
        } catch {
            logger.error("바로 읽기 실패: \(error.localizedDescription)")
            errorMessage = "서재에 저장하지 못했습니다. 다시 시도해 주세요."
        }
    }

    func saveToWishlist() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let existing = try repository.fetchBy(isbn: book.id)
            guard existing == nil else { return }

            let newBook = LibraryBook(from: book, status: .wantToRead)
            try repository.add(newBook)
            libraryState = .wantToRead(id: newBook.id)
        } catch LibraryRepositoryError.duplicateISBN {
            await loadLibraryState()
        } catch {
            logger.error("위시리스트 저장 실패: \(error.localizedDescription)")
            errorMessage = "서재에 저장하지 못했습니다. 다시 시도해 주세요."
        }
    }

    func removeFromWishlist() async {
        guard case .wantToRead(let id) = libraryState else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try repository.delete(id: id)
            libraryState = .notInLibrary
        } catch {
            logger.error("위시리스트 삭제 실패: \(error.localizedDescription)")
            errorMessage = "서재에서 삭제하지 못했습니다. 다시 시도해 주세요."
        }
    }

    // MARK: - Private

    private func makeLibraryState(from book: LibraryBook?) -> LibraryState {
        guard let book else { return .notInLibrary }
        switch book.status {
        case .wantToRead: return .wantToRead(id: book.id)
        case .reading:    return .reading(id: book.id)
        case .completed:  return .completed(id: book.id)
        }
    }
}

// MARK: - UI 연산 프로퍼티

extension BookDetailViewModel {

    var readNowButtonLabel: String {
        switch libraryState {
        case .notInLibrary, .wantToRead: return "바로 읽기"
        case .reading:                   return "읽고 있는 중"
        case .completed:                 return "완독한 책"
        }
    }

    var isReadNowEnabled: Bool {
        switch libraryState {
        case .notInLibrary, .wantToRead, .reading: return true
        case .completed:                            return false
        }
    }

    var showWishlistButton: Bool {
        switch libraryState {
        case .notInLibrary, .wantToRead: return true
        case .reading, .completed:       return false
        }
    }

    var wishlistIconName: String {
        switch libraryState {
        case .wantToRead: return "bookmark.fill"
        default:          return "bookmark"
        }
    }

    var wishlistAccessibilityLabel: String {
        switch libraryState {
        case .notInLibrary: return "읽고 싶은 책에 저장"
        case .wantToRead:   return "저장됨, 탭하면 제거"
        default:            return ""
        }
    }

    func toggleWishlist() async {
        switch libraryState {
        case .notInLibrary: await saveToWishlist()
        case .wantToRead:   await removeFromWishlist()
        default: break
        }
    }
}
