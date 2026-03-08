//
//  EnvironmentValues+Repository.swift
//  Booktory
//

import SwiftUI

private struct LibraryRepositoryKey: EnvironmentKey {
    // Preview·테스트 기본값. 실제 앱은 RootView에서 DefaultLibraryRepository로 교체한다.
    static let defaultValue: any LibraryRepositoryProtocol = PreviewLibraryRepository()
}

extension EnvironmentValues {
    var libraryRepository: any LibraryRepositoryProtocol {
        get { self[LibraryRepositoryKey.self] }
        set { self[LibraryRepositoryKey.self] = newValue }
    }
}
