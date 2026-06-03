//
//  AppDelegate.swift
//  Booktory
//
//  앱 종료 시점(applicationWillTerminate)에 LiveActivity를 정리한다.
//  force quit 시 async end()가 완료되기 전에 프로세스가 종료될 수 있으므로
//  Task.detached + DispatchSemaphore로 완료를 보장한다.
//

import UIKit
import ActivityKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func applicationWillTerminate(_ application: UIApplication) {
        let semaphore = DispatchSemaphore(value: 0)

        Task.detached(priority: .high) {
            for activity in Activity<TimerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            semaphore.signal()
        }

        // 최대 2초 대기 — 그 안에 end()가 완료되지 않으면 프로세스 종료에 맡긴다
        _ = semaphore.wait(timeout: .now() + 2)
    }
}
