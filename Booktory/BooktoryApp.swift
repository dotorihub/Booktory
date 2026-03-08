//
//  BooktoryApp.swift
//  Booktory
//

import SwiftUI
import SwiftData

@main
struct BooktoryApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
        }
        .modelContainer(for: [LibraryBook.self, ReadingSession.self])
    }
}

// MARK: - RootView
// ModelContext 환경 값을 받아 DefaultLibraryRepository를 주입한다.
// BooktoryApp에서 직접 접근할 수 없는 modelContext를 뷰 계층에서 가져오기 위한 래퍼.

private struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        MainView()
            .environment(
                \.libraryRepository,
                DefaultLibraryRepository(context: modelContext)
            )
    }
}
