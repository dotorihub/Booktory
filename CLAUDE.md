# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Booktory is an iOS app (SwiftUI) for tracking reading sessions. It integrates with the Naver Books Open API to search books and includes a reading timer with background support.

## Building & Running

This is a native Xcode project — there is no CLI build command. Open `Booktory.xcodeproj` in Xcode and run on a simulator or device (⌘R).

- **Minimum deployment target**: set in project settings (check `Booktory.xcodeproj`)
- **API credentials**: stored in `Booktory/Configs/Secrets.xcconfig` (gitignored). The file must exist locally with `API_CLIENT_ID` and `API_CLIENT_SECRET` values for the Naver API to work. Values flow into `Info.plist` via build settings and are read at runtime through `AppConfig`.

## Architecture

### Tab Structure (`MainView`)
Four tabs managed by a `TabView`:
- **Tab 0** — `TimerMainView` (reading session hub; links to tab 2 to find a book)
- **Tab 1** — "내 기록" (placeholder)
- **Tab 2** — `SearchView` (book search)
- **Tab 3** — Profile (placeholder)

### Networking Layer
`Booktory/Networking/`

| File | Role |
|---|---|
| `NetworkClient.swift` | Protocol + `DefaultNetworkClient` wrapping `URLSession` |
| `APIEndpoint.swift` | Value type that builds a `URLRequest` from path/method/headers/query |
| `APIError.swift` | `LocalizedError` enum covering all failure cases |
| `Service/BookSearchService.swift` | Protocol + `DefaultBookSearchService` — calls Naver Books `/v1/search/book.json` |
| `Model/BookModels.swift` | `NaverBookItem` (API DTO) → `Book` (app model, strips HTML tags) |

`AppConfig` reads `API_BASE_URL`, `API_CLIENT_ID`, `API_CLIENT_SECRET` from `Bundle.main.infoDictionary` (populated from `Secrets.xcconfig` via `Info.plist`).

### Search Feature (`UI/Search/`)
- **`SearchViewModel`** (`@MainActor ObservableObject`): owns search state machine (`idle | loading | loaded([Book]) | failed(String)`), debounced search (350 ms), pagination (20 items/page, triggered when last item appears).
- **`SearchView`**: renders state via `@ViewBuilder content`, uses `LazyVStack` + `onAppear` for infinite scroll.

### Timer Feature (`UI/Timer/`)
- **`TimerView`**: full-screen reading timer with start/pause/resume. Uses `Timer.publish` for 1-second UI ticks; tracks elapsed time across pauses via `elapsedBeforePause + Date().timeIntervalSince(startDate)`.
- **`TimerMainView`**: home tab that presents `TimerView` as a `.fullScreenCover`. Has a "Find a Book" button that switches to tab 2 via `@Binding var selectedTab`.
- **`BGTimer/`**: scaffolding for Live Activity support (`LiveActivityManager`, `LiveTimerWidget`, `TimerActivityAttributes`) — currently empty/stub.

### Resources
- `Color+.swift` — custom `Color` extensions (e.g., `Color.paperGray`)
- `Assets.xcassets` — app icon and accent color
