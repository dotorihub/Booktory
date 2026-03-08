//
//  MainView.swift
//  Booktory
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        TabView(selection: Binding(
            get: { coordinator.selectedTab },
            set: { coordinator.selectedTab = $0 }
        )) {
            ReadingTabView()
                .tabItem {
                    Label(AppCoordinator.Tab.reading.title,
                          systemImage: AppCoordinator.Tab.reading.icon)
                }
                .tag(AppCoordinator.Tab.reading)
                .accessibilityLabel(AppCoordinator.Tab.reading.title)

            SearchView()
                .tabItem {
                    Label(AppCoordinator.Tab.search.title,
                          systemImage: AppCoordinator.Tab.search.icon)
                }
                .tag(AppCoordinator.Tab.search)
                .accessibilityLabel(AppCoordinator.Tab.search.title)

            RecordTabView()
                .tabItem {
                    Label(AppCoordinator.Tab.record.title,
                          systemImage: AppCoordinator.Tab.record.icon)
                }
                .tag(AppCoordinator.Tab.record)
                .accessibilityLabel(AppCoordinator.Tab.record.title)

            LibraryTabView()
                .tabItem {
                    Label(AppCoordinator.Tab.library.title,
                          systemImage: AppCoordinator.Tab.library.icon)
                }
                .tag(AppCoordinator.Tab.library)
                .accessibilityLabel(AppCoordinator.Tab.library.title)
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppCoordinator())
}
