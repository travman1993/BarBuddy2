//
//  ContentView.swift
//  BarBuddy2Watch Watch App
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Views/ContentView.swift

import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var drinkTracker: DrinkTrackerWatch
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var selectedTab = 0
    @State private var showingSyncIndicator = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab - Main drink tracking screen
            DashboardView()
                .tag(0)
            
            // Quick Add Tab - Fast drink logging
            QuickAddView()
                .tag(1)
            
            // Emergency Tab - Safety features
            EmergencyView()
                .tag(2)
            
            // Settings Tab - Basic configuration
            SettingsView()
                .tag(3)
        }
        .tabViewStyle(PageTabViewStyle())
        .navigationTitle(getNavigationTitle())
        .overlay(
            // Sync indicator overlay
            Group {
                if showingSyncIndicator {
                    SyncIndicatorView()
                        .transition(.opacity)
                }
            }
        )
        .handleDeepLink(tabSelection: $selectedTab)
        .onAppear {
            // Request data from phone when view appears
            requestDataFromPhone()
        }
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)) { _ in
            // Request data when app becomes active
            requestDataFromPhone()
        }
        .onReceive(sessionManager.$isPhoneAppAvailable) { isAvailable in
            // Show sync indicator when connection status changes
            if isAvailable {
                showSyncAnimation()
            }
        }
    }
    
    private func getNavigationTitle() -> String {
        switch selectedTab {
        case 0:
            return "Dashboard"
        case 1:
            return "Quick Add"
        case 2:
            return "Emergency"
        case 3:
            return "Settings"
        default:
            return "BarBuddy"
        }
    }
    
    private func requestDataFromPhone() {
        showSyncAnimation()
        sessionManager.requestDrinkDataFromPhone()
    }
    
    private func showSyncAnimation() {
        // Show sync indicator
        withAnimation {
            showingSyncIndicator = true
        }
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingSyncIndicator = false
            }
        }
    }
}

// MARK: - Sync Indicator View
struct SyncIndicatorView: View {
    @State private var isRotating = false
    
    var body: some View {
        VStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .rotationEffect(Angle.degrees(isRotating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isRotating
                )
                .onAppear {
                    isRotating = true
                }
            
            Text("Syncing...")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var drinkTracker: DrinkTrackerWatch
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var showingDetails = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Drink Counter with Safety Status
                DrinkCounterView(
                    drinkCount: drinkTracker.standardDrinkCount,
                    drinkLimit: drinkTracker.drinkLimit,
                    safetyStatus: drinkTracker.getSafetyStatus()
                )
                .padding(.horizontal, 4)
                
                // Time until reset
                if drinkTracker.timeUntilReset > 0 {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                        Text("Reset in: \(drinkTracker.getFormattedTimeUntilReset())")
                            .font(.footnote)
                    }
                    .padding(.top, 4)
                }
                
                // Quick Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        sessionManager.requestDrinkDataFromPhone()
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(20)
                    
                    Button(action: {
                        WKInterfaceDevice.current().play(.click)
                        withAnimation {
                            showingDetails.toggle()
                        }
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 40, height: 40)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(20)
                }
                .padding(.top, 8)
                
                // Show last few drinks
                if !drinkTracker.drinks.isEmpty {
                    Text("Recent Drinks")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    
                    ForEach(Array(drinkTracker.drinks.prefix(3).enumerated()), id: \.element.id) { index, drink in
                        HStack {
                            Text(drink.type.icon)
                            Text("\(drink.type.rawValue)")
                                .font(.caption2)
                            Spacer()
                            Text("\(String(format: "%.1f", drink.standardDrinks))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        
                        if index < min(2, drinkTracker.drinks.count - 1) {
                            Divider()
                        }
                    }
                } else {
                    Text("No drinks recorded yet")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                
                // Connection status
                HStack {
                    Image(systemName: sessionManager.isPhoneAppAvailable ? "iphone.circle.fill" : "iphone.slash")
                        .foregroundColor(sessionManager.isPhoneAppAvailable ? .green : .red)
                        .font(.caption2)
                    
                    Text(sessionManager.isPhoneAppAvailable ? "Connected" : "Standalone")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingDetails) {
            DrinkDetailsView()
        }
    }
}

// MARK: - Drink Counter View
struct DrinkCounterView: View {
    let drinkCount: Double
    let drinkLimit: Double
    let safetyStatus: SafetyStatus
    
    var statusColor: Color {
        switch safetyStatus {
        case .safe: return .green
        case .borderline: return .yellow
        case .unsafe: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Drink count display
            HStack(alignment: .bottom) {
                Text("\(String(format: "%.1f", drinkCount))")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(statusColor)
                
                Text("/ \(String(format: "%.1f", drinkLimit))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    // Progress bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: min(CGFloat(drinkCount / drinkLimit) * geometry.size.width, geometry.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            // Status text
            Text(safetyStatus.rawValue)
                .font(.caption2)
                .foregroundColor(statusColor)
                .padding(.top, 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Drink Details View
struct DrinkDetailsView: View {
    @EnvironmentObject var drinkTracker: DrinkTrackerWatch
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Drink Stats")
                    .font(.headline)
                
                // Standard drinks today
                HStack {
                    Text("Current Count:")
                    Spacer()
                    Text("\(String(format: "%.1f", drinkTracker.standardDrinkCount))")
                        .fontWeight(.bold)
                }
                
                // Limit
                HStack {
                    Text("Drink Limit:")
                    Spacer()
                    Text("\(String(format: "%.1f", drinkTracker.drinkLimit))")
                }
                
                // Time until reset
                if drinkTracker.timeUntilReset > 0 {
                    HStack {
                        Text("Reset in:")
                        Spacer()
                        Text(drinkTracker.getFormattedTimeUntilReset())
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // User info
                Text("User Profile")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("Weight:")
                    Spacer()
                    Text("\(Int(drinkTracker.userWeight)) lbs")
                }
                
                HStack {
                    Text("Gender:")
                    Spacer()
                    Text(drinkTracker.userGender.rawValue)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // Last sync time
                Text("Last synced: \(drinkTracker.formatTimeSinceSync())")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding()
        }
    }
}
