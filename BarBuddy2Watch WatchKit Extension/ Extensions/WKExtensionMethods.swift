//
//  WKExtensionMethods.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Extensions/WKExtensionMethods.swift

import WatchKit
import SwiftUI

// MARK: - Deep Link Handling
struct DeepLink {
    static let scheme = "barbuddy"
    
    enum Destination: String {
        case dashboard = "dashboard"
        case quickAdd = "add"
        case emergency = "emergency"
        case settings = "settings"
        case unknown
        
        init(from url: URL) {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  components.scheme == DeepLink.scheme,
                  let host = components.host else {
                self = .unknown
                return
            }
            
            self = Destination(rawValue: host) ?? .unknown
        }
    }
    
    static func handle(_ url: URL, tabSelection: Binding<Int>) {
        let destination = Destination(from: url)
        
        switch destination {
        case .dashboard:
            tabSelection.wrappedValue = 0
        case .quickAdd:
            tabSelection.wrappedValue = 1
        case .emergency:
            tabSelection.wrappedValue = 2
        case .settings:
            tabSelection.wrappedValue = 3
        case .unknown:
            // Default to dashboard
            tabSelection.wrappedValue = 0
        }
    }
}

// MARK: - WKInterfaceController Extensions
extension WKExtension {
    /// Navigates to a specific screen in the app
    func navigateTo(_ destination: DeepLink.Destination) {
        // Use NotificationCenter to communicate with ContentView
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToDestination"),
            object: nil,
            userInfo: ["destination": destination.rawValue]
        )
    }
    
    /// Opens a URL, handling both internal and external URLs
    func openURL(_ url: URL) {
        if url.scheme == DeepLink.scheme {
            // Internal deep link
            let destination = DeepLink.Destination(from: url)
            navigateTo(destination)
        } else {
            // External URL - open on phone
            WKExtension.shared().openSystemURL(url)
        }
    }
    
    /// Sends a notification to the user
    func sendLocalNotification(
        title: String,
        body: String,
        category: String? = nil,
        userInfo: [String: Any] = [:],
        at date: Date = Date()
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let category = category {
            content.categoryIdentifier = category
        }
        
        content.userInfo = userInfo
        content.sound = .default
        
        // Create the trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - View Navigation Extension
extension View {
    /// Adds a deep link handler to any view
    func handleDeepLink(tabSelection: Binding<Int>) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToDestination"))) { notification in
            if let destinationString = notification.userInfo?["destination"] as? String,
               let destination = DeepLink.Destination(rawValue: destinationString) {
                
                switch destination {
                case .dashboard:
                    tabSelection.wrappedValue = 0
                case .quickAdd:
                    tabSelection.wrappedValue = 1
                case .emergency:
                    tabSelection.wrappedValue = 2
                case .settings:
                    tabSelection.wrappedValue = 3
                case .unknown:
                    break
                }
            }
        }
    }
}

// MARK: - Notification Configuration
func setupNotificationCategories() {
    // Create actions for notifications
    let getUberAction = UNNotificationAction(
        identifier: "GET_UBER",
        title: "Get Uber",
        options: .foreground
    )
    
    let getLyftAction = UNNotificationAction(
        identifier: "GET_LYFT",
        title: "Get Lyft",
        options: .foreground
    )
    
    let logWaterAction = UNNotificationAction(
        identifier: "LOG_WATER",
        title: "Log Water",
        options: .foreground
    )
    
    let dismissAction = UNNotificationAction(
        identifier: "DISMISS",
        title: "Dismiss",
        options: .destructive
    )
    
    // Create notification categories
    let bacCategory = UNNotificationCategory(
        identifier: "BAC_ALERT",
        actions: [getUberAction, getLyftAction, dismissAction],
        intentIdentifiers: [],
        options: []
    )
    
    let hydrationCategory = UNNotificationCategory(
        identifier: "HYDRATION_REMINDER",
        actions: [logWaterAction, dismissAction],
        intentIdentifiers: [],
        options: []
    )
    
    let durationCategory = UNNotificationCategory(
        identifier: "DURATION_ALERT",
        actions: [getUberAction, getLyftAction, dismissAction],
        intentIdentifiers: [],
        options: []
    )
    
    let checkInCategory = UNNotificationCategory(
        identifier: "AFTER_PARTY_REMINDER",
        actions: [dismissAction],
        intentIdentifiers: [],
        options: []
    )
    
    let drinkLimitCategory = UNNotificationCategory(
        identifier: "DRINKING_LIMIT",
        actions: [getUberAction, getLyftAction, dismissAction],
        intentIdentifiers: [],
        options: []
    )
    
    // Register the notification categories
    UNUserNotificationCenter.current().setNotificationCategories([
        bacCategory,
        hydrationCategory,
        durationCategory,
        checkInCategory,
        drinkLimitCategory
    ])
}
