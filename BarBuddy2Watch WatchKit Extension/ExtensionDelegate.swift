//
//  ExtensionDelegate.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/ExtensionDelegate.swift

import WatchKit
import UserNotifications
import ClockKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, UNUserNotificationCenterDelegate {
    // MARK: - Lifecycle Methods
    
    func applicationDidFinishLaunching() {
        // Setup notification handling
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
        
        // Activate WatchKit session
        WatchSessionManager.shared.setupSession()
        
        // Schedule complication updates
        scheduleBackgroundRefresh()
    }
    
    func applicationDidBecomeActive() {
        // Update data when app becomes active
        WatchSessionManager.shared.requestDrinkDataFromPhone()
        updateAllComplications()
    }
    
    // MARK: - Background Task Handling
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let complicationTask as WKApplicationRefreshBackgroundTask:
                // Update complications data
                WatchSessionManager.shared.requestDrinkDataFromPhone()
                updateAllComplications()
                
                // Schedule next update
                scheduleBackgroundRefresh()
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a completely separate lifecycle
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date(timeIntervalSinceNow: 60 * 60),
                    userInfo: nil
                )
                
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Complete URL session task
                urlSessionTask.setTaskCompletedWithSnapshot(false)
                
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Complete relevant shortcut task
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
                
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Complete intent handling task
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
                
            default:
                // For any other task type, complete with snapshot
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    // MARK: - Complication Management
    
    func scheduleBackgroundRefresh() {
        // Schedule next update in 15 minutes
        let refreshDate = Date().addingTimeInterval(15 * 60) // 15 minutes
        
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: refreshDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("Failed to schedule background refresh: \(error.localizedDescription)")
            } else {
                print("Scheduled next complication update for \(refreshDate)")
            }
        }
    }
    
    func updateAllComplications() {
        // Get the complication server
        let server = CLKComplicationServer.sharedInstance()
        
        // Update all active complications
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Allow banner and sound for notifications while app is active
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification actions
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        switch actionIdentifier {
        case "GET_UBER":
            // Open Uber app or deep link
            if let url = URL(string: "uber://") {
                WKExtension.shared().openSystemURL(url)
            }
            
        case "GET_LYFT":
            // Open Lyft app or deep link
            if let url = URL(string: "lyft://") {
                WKExtension.shared().openSystemURL(url)
            }
            
        case "LOG_WATER":
            // Log water consumption
            // In a real app, this would log water to the health app
            // For now, just provide feedback
            WKInterfaceDevice.current().play(.success)
            
        case UNNotificationDefaultActionIdentifier:
            // Default action (tapping notification)
            // Navigate to appropriate screen based on category
            switch categoryIdentifier {
            case "BAC_ALERT", "DRINKING_LIMIT":
                // Navigate to dashboard
                WKExtension.shared().navigateTo(.dashboard)
                
            case "HYDRATION_REMINDER":
                // No special action needed
                break
                
            case "DURATION_ALERT":
                // Navigate to emergency view
                WKExtension.shared().navigateTo(.emergency)
                
            case "AFTER_PARTY_REMINDER":
                // Navigate to dashboard
                WKExtension.shared().navigateTo(.dashboard)
                
            default:
                break
            }
            
        default:
            break
        }
        
        completionHandler()
    }
}
