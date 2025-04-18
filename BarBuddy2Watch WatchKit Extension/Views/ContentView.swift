//
//  ContentView.swift
//  BarBuddy2Watch Watch App
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Views/ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var drinkTracker: DrinkTrackerWatch
    @State private var selectedTab = 0
    
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
        .navigationTitle(getNavigationTitle())
        .tabViewStyle(PageTabViewStyle())
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
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Quick Add View
struct QuickAddView: View {
    @EnvironmentObject var drinkTracker: DrinkTrackerWatch
    
    let drinkTypes: [DrinkType] = DrinkType.allCases
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Quick Add Drink")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Grid of drink types
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(drinkTypes, id: \.self) { drinkType in
                        DrinkTypeButton(drinkType: drinkType) {
                            // Add drink of selected type
                            drinkTracker.quickAddDrink(type: drinkType)
                            
                            // Provide haptic feedback
                            WKInterfaceDevice.current().play(.success)
                        }
                    }
                }
                
                // Current Standard Drinks Counter
                HStack {
                    Text("Current Total:")
                        .font(.footnote)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", drinkTracker.standardDrinkCount)) / \(String(format: "%.1f", drinkTracker.drinkLimit))")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(drinkTracker.getSafetyStatus().color)
                }
                .padding(.top, 8)
            }
            .padding(8)
        }
    }
}

// MARK: - Drink Type Button
struct DrinkTypeButton: View {
    let drinkType: DrinkType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Emoji icon
                Text(drinkType.icon)
                    .font(.title3)
                
                // Drink type name
                Text(drinkType.rawValue)
                    .font(.caption2)
                
                // Drink properties
                Text("\(String(format: "%.1f", drinkType.defaultSize))oz, \(Int(drinkType.defaultAlcoholPercentage))%")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(drinkType.color.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Emergency View
struct EmergencyView: View {
    @State private var showingEmergencySheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Emergency Button
                Button(action: {
                    showingEmergencySheet = true
                }) {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Emergency")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                
                // Ride Options
                VStack(spacing: -4) {
                    Text("Get a Ride")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        RideButton(service: "Uber", icon: "car.fill") {
                            // Action would open Uber deep link
                            // In a real app, would use WKExtension.shared().openSystemURL()
                        }
                        
                        RideButton(service: "Lyft", icon: "car.fill") {
                            // Action would open Lyft deep link
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Emergency Contacts
                VStack(spacing: 8) {
                    Text("Emergency Contacts")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    EmergencyContactButton(name: "Call Contact", icon: "person.circle.fill") {
                        // Would access emergency contacts in a real app
                    }
                    
                    EmergencyContactButton(name: "Send Location", icon: "location.circle.fill") {
                        // Would send location to emergency contacts
                    }
                }
                .padding(.top, 8)
                
                // Safety Tips
                VStack(spacing: 8) {
                    Text("Safety Tips")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Stay hydrated: drink water between alcoholic drinks")
                        .font(.caption2)
                        .multilineTextAlignment(.leading)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            .padding(12)
        }
        .sheet(isPresented: $showingEmergencySheet) {
            EmergencySheetView()
        }
    }
}

// Emergency Sheet View
struct EmergencySheetView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Emergency Options")
                .font(.headline)
            
            Button(action: {
                // Would call emergency contact
                presentationMode.wrappedValue.dismiss()
            }) {
                Label("Call Emergency Contact", systemImage: "phone.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            Button(action: {
                // Would call 911
                presentationMode.wrappedValue.dismiss()
            }) {
                Label("Call 911", systemImage: "phone.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            
            Button(action: {
                // Would get a ride
                presentationMode.wrappedValue.dismiss()
            }) {
                Label("Get Ride Home", systemImage: "car.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.gray)
            .padding(.top, 8)
        }
        .padding(12)
    }
}

// Ride Button
struct RideButton: View {
    let service: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.body)
                
                Text(service)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Emergency Contact Button
struct EmergencyContactButton: View {
    let name: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                
                Text(name)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var drinkTracker: DrinkTrackerWatch
    @EnvironmentObject var sessionManager: WatchSessionManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // App Status Section
                VStack(spacing: 8) {
                    Text("App Status")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Image(systemName: sessionManager.isPhoneAppAvailable ? "iphone.circle.fill" : "iphone.slash")
                            .foregroundColor(sessionManager.isPhoneAppAvailable ? .green : .red)
                        
                        Text(sessionManager.isPhoneAppAvailable ? "Phone Connected" : "Phone Not Connected")
                            .font(.caption)
                        
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Sync Section
                VStack(spacing: 8) {
                    Text("Synchronization")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: {
                        // Sync data from phone
                        sessionManager.requestDrinkDataFromPhone()
                        sessionManager.requestUserProfileFromPhone()
                        
                        // Provide haptic feedback
                        WKInterfaceDevice.current().play(.click)
                    }) {
                        Label("Sync with Phone", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Last sync: \(drinkTracker.formatTimeSinceSync())")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                // User Info Section
                VStack(spacing: 8) {
                    Text("User Profile")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("Weight:")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(drinkTracker.userWeight)) lbs")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    
                    HStack {
                        Text("Gender:")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(drinkTracker.userGender.rawValue)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                }
                
                // About Section
                VStack(spacing: 8) {
                    Text("About")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("BarBuddy Watch+ v1.0")
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Sync with BarBuddy2 on your iPhone for full features")
                        .font(.system(size: 9))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
            }
            .padding(12)
        }
    }
}, 4)
                }
                
                // Quick Action Buttons
                HStack {
                    Button(action: {
                        sessionManager.requestDrinkDataFromPhone()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(20)
                    
                    Button(action: {
                        selectedTab = 1 // Switch to Quick Add tab
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 40, height: 40)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(20)
                    
                    Button(action: {
                        showingDetails.toggle()
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
                }
                
                // Connection status
                HStack {
                    Image(systemName: sessionManager.isPhoneAppAvailable ? "iphone.homebutton" : "iphone.slash")
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
                .padding(.top
