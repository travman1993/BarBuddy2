//
//  BarBuddy2WatchApp.swift
//  BarBuddy2Watch Watch App
//
//  Created by Travis Rodriguez on 4/17/25.
//
import SwiftUI

@main
struct BarBuddy2WatchApp: App {
    // State objects for managing app data
    @StateObject private var watchSessionManager = WatchSessionManager.shared
    @StateObject private var drinkTrackerWatch = DrinkTrackerWatch.shared
    
    // Handle background tasks and notifications
    @WKApplicationDelegateAdaptor private var appDelegate: BarBuddy2WatchDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchSessionManager)
                .environmentObject(drinkTrackerWatch)
                .onAppear {
                    // Request initial data from phone when app launches
                    watchSessionManager.requestDrinkDataFromPhone()
                }
        }
    }
}

// WatchKit App Delegate for handling background tasks
class BarBuddy2WatchDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Setup initial state, connectivity, etc.
        WatchSessionManager.shared.setupSession()
    }
    
    func applicationDidBecomeActive() {
        // App becomes active, refresh data
        WatchSessionManager.shared.requestDrinkDataFromPhone()
    }
    
    func applicationWillEnterForeground() {
        // App coming to foreground, refresh data
        WatchSessionManager.shared.requestDrinkDataFromPhone()
    }
    
    // Handle complications
    func handleBackgroundTasks(for backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let complicationTask = task as? WKApplicationRefreshBackgroundTask {
                // Schedule next update for complications
                let nextUpdate = Date().addingTimeInterval(15 * 60) // 15 minutes
                WKExtension.shared().scheduleBackgroundRefresh(
                    withPreferredDate: nextUpdate,
                    userInfo: nil,
                    scheduledCompletion: { _ in }
                )
            }
            
            // Mark task complete
            task.setTaskCompleted()
        }
    }
}
