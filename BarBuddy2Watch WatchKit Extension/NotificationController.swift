//
//  NotificationController.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/NotificationController.swift

import WatchKit
import SwiftUI
import UserNotifications

class NotificationController: WKUserNotificationHostingController<NotificationView> {
    var drinkCount: Double = 0
    var drinkLimit: Double = 4.0
    var safetyStatus: SafetyStatus = .safe
    var notificationType: String = "standard"
    
    override var body: NotificationView {
        return NotificationView(
            drinkCount: drinkCount,
            drinkLimit: drinkLimit,
            safetyStatus: safetyStatus,
            notificationType: notificationType
        )
    }
    
    override func didReceive(_ notification: UNNotification) {
        // Extract the notification data
        let content = notification.request.content
        let userInfo = content.userInfo
        
        // Set notification type
        if let category = content.categoryIdentifier as String? {
            switch category {
            case "BAC_ALERT", "DRINKING_LIMIT":
                notificationType = "limit"
            case "HYDRATION_REMINDER":
                notificationType = "hydration"
            case "DURATION_ALERT":
                notificationType = "duration"
            case "AFTER_PARTY_REMINDER":
                notificationType = "checkIn"
            default:
                notificationType = "standard"
            }
        }
        
        // Extract drink data from notification payload
        if let drinkCountValue = userInfo["drinkCount"] as? Double {
            drinkCount = drinkCountValue
        }
        
        if let drinkLimitValue = userInfo["drinkLimit"] as? Double {
            drinkLimit = drinkLimitValue
        }
        
        // Calculate safety status based on drink count
        if drinkCount >= drinkLimit {
            safetyStatus = .unsafe
        } else if drinkCount >= drinkLimit * 0.75 {
            safetyStatus = .borderline
        } else {
            safetyStatus = .safe
        }
        
        // Update the view
        let drinkTracker = DrinkTrackerWatch.shared
        drinkTracker.updateFromPhoneData(
            drinkCount: drinkCount,
            drinkLimit: drinkLimit,
            timeUntilReset: drinkTracker.timeUntilReset
        )
    }
}

// MARK: - Notification View
struct NotificationView: View {
    var drinkCount: Double
    var drinkLimit: Double
    var safetyStatus: SafetyStatus
    var notificationType: String
    
    var body: some View {
        VStack(spacing: 10) {
            // Header with icon
            HStack {
                Image(systemName: iconForNotificationType)
                    .font(.title3)
                    .foregroundColor(safetyStatus.color)
                
                Text(titleForNotificationType)
                    .font(.headline)
                    .foregroundColor(safetyStatus.color)
            }
            .padding(.bottom, 4)
            
            // Drink info
            if notificationType != "hydration" && notificationType != "checkIn" {
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", drinkCount))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(safetyStatus.color)
                    
                    Text("/ \(String(format: "%.1f", drinkLimit))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Message
            Text(messageForNotificationType)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
            
            // Action buttons for specific notification types
            if notificationType == "limit" || notificationType == "duration" {
                HStack {
                    ActionButton(title: "Ride", icon: "car.fill") {
                        // Action would open ride share options
                    }
                    
                    ActionButton(title: "Alert", icon: "bell.fill") {
                        // Action would alert emergency contact
                    }
                }
                .padding(.top, 4)
            } else if notificationType == "hydration" {
                ActionButton(title: "Logged Water", icon: "drop.fill") {
                    // Action would log water consumption
                    WKInterfaceDevice.current().play(.success)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
    }
    
    // Get icon based on notification type
    private var iconForNotificationType: String {
        switch notificationType {
        case "limit":
            return "exclamationmark.triangle.fill"
        case "hydration":
            return "drop.fill"
        case "duration":
            return "clock.fill"
        case "checkIn":
            return "checkmark.circle.fill"
        default:
            return "wineglass.fill"
        }
    }
    
    // Get title based on notification type
    private var titleForNotificationType: String {
        switch notificationType {
        case "limit":
            return "Drink Limit Alert"
        case "hydration":
            return "Hydration Reminder"
        case "duration":
            return "Drinking Duration"
        case "checkIn":
            return "Morning Check-In"
        default:
            return "BarBuddy"
        }
    }
    
    // Get message based on notification type
    private var messageForNotificationType: String {
        switch notificationType {
        case "limit":
            return "You've reached your drink limit. Consider switching to water or heading home."
        case "hydration":
            return "Remember to drink water between alcoholic drinks to stay hydrated."
        case "duration":
            return "You've been drinking for an extended period. Consider taking a break or getting a ride home."
        case "checkIn":
            return "Good morning! How are you feeling today? Remember to hydrate and rest if needed."
        default:
            return "Keep track of your drinks and stay safe!"
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                
                Text(title)
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
