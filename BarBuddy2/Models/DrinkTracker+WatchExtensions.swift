//
//  DrinkTracker+WatchExtensions.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2/Models/DrinkTracker+WatchExtensions.swift

import Foundation
import Combine

// MARK: - Watch Connectivity Extensions for DrinkTracker
extension DrinkTracker {
    /**
     * Updates the watch with current drink data whenever changes occur.
     * This method should be called when drink data changes.
     */
    func updateWatchData() {
        WatchSessionManager.shared.sendDrinkDataToWatch(
            drinkCount: standardDrinkCount,
            drinkLimit: drinkLimit,
            timeUntilReset: timeUntilReset
        )
        
        // Update complications if supported
        WatchSessionManager.shared.updateComplications()
    }
    
    /**
     * Sends the current user profile to the watch.
     * This should be called when user profile info changes.
     */
    func updateWatchUserProfile() {
        WatchSessionManager.shared.sendUserProfileToWatch()
    }
    
    /**
     * Override point for addDrink method to update watch after adding a drink.
     */
    func addDrinkWithWatchSync(type: DrinkType, size: Double, alcoholPercentage: Double) {
        // Add the drink using standard method
        addDrink(type: type, size: size, alcoholPercentage: alcoholPercentage)
        
        // Update watch
        updateWatchData()
    }
    
    /**
     * Override point for removeDrink method to update watch after removing a drink.
     */
    func removeDrinkWithWatchSync(_ drink: Drink) {
        // Remove the drink using standard method
        removeDrink(drink)
        
        // Update watch
        updateWatchData()
    }
    
    /**
     * Override point for updateDrinkLimit method to update watch after changing limit.
     */
    func updateDrinkLimitWithWatchSync(_ limit: Double) {
        // Update the limit using standard method
        updateDrinkLimit(limit)
        
        // Update watch
        updateWatchData()
    }
    
    /**
     * Override point for updateUserProfile method to update watch with new profile.
     */
    func updateUserProfileWithWatchSync(_ profile: UserProfile) {
        // Update the profile using standard method
        updateUserProfile(profile)
        
        // Update watch
        updateWatchUserProfile()
    }
}

// MARK: - SwiftUI Watch Integration for Main App
#if os(iOS)
import SwiftUI

// Watch connectivity status indicator for iOS app
struct WatchConnectivityStatusView: View {
    @ObservedObject var sessionManager = WatchSessionManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: sessionManager.isWatchAppInstalled ?
                (sessionManager.isReachable ? "applewatch.radiowaves.left.and.right" : "applewatch.slash") :
                "applewatch")
                .foregroundColor(sessionManager.isReachable ? .green : .secondary)
                .font(.system(size: 14))
            
            if sessionManager.isWatchAppInstalled {
                Text(sessionManager.isReachable ? "Watch Connected" : "Watch Unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Watch App Not Installed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// Watch settings section for settings view
struct WatchSettingsSection: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    @ObservedObject var sessionManager = WatchSessionManager.shared
    @State private var showingSyncConfirmation = false
    
    var body: some View {
        Section(header: Text("APPLE WATCH")) {
            if sessionManager.isWatchAppInstalled {
                Toggle("Enable Watch Sync", isOn: $settingsManager.syncWithAppleWatch)
                    .onChange(of: settingsManager.syncWithAppleWatch) { oldValue, newValue in
                        if newValue {
                            // Force sync data when enabled
                            sessionManager.forceWatchUpdate()
                        }
                    }
                
                Toggle("Quick Add from Watch", isOn: $settingsManager.watchQuickAdd)
                
                Toggle("Watch Complications", isOn: $settingsManager.watchComplication)
                
                Button(action: {
                    showingSyncConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Force Sync to Watch")
                    }
                }
                .alert(isPresented: $showingSyncConfirmation) {
                    Alert(
                        title: Text("Sync with Watch"),
                        message: Text("Send current data to Apple Watch?"),
                        primaryButton: .default(Text("Sync")) {
                            // Force sync all data to watch
                            sessionManager.forceWatchUpdate()
                            
                            // Add a small delay and update complications
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                sessionManager.updateComplications()
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                if let lastSync = sessionManager.watchLastSync {
                    HStack {
                        Text("Last Watch Sync:")
                        Spacer()
                        Text(formatLastSync(lastSync))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Apple Watch app not installed")
                    .foregroundColor(.secondary)
                
                Link("Learn about BarBuddy Watch+", destination: URL(string: "https://barbuddy.app/watch")!)
            }
        }
    }
    
    private func formatLastSync(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Watch sync indicator for dashboard
struct WatchSyncIndicator: View {
    @ObservedObject var sessionManager = WatchSessionManager.shared
    
    var body: some View {
        if sessionManager.isWatchAppInstalled && sessionManager.isReachable {
            HStack(spacing: 4) {
                Image(systemName: "applewatch")
                    .font(.system(size: 12))
                
                if let lastSync = sessionManager.watchLastSync {
                    Text("Synced \(timeAgo(lastSync))")
                        .font(.system(size: 10))
                } else {
                    Text("Not synced")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        } else {
            EmptyView()
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
#endif
