//
//  DrinkTrackerWatch.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Models/DrinkTrackerWatch.swift

import Foundation
import Combine
import WatchKit

class DrinkTrackerWatch: ObservableObject {
    // Singleton instance
    static let shared = DrinkTrackerWatch()
    
    // Published properties for UI updates
    @Published private(set) var drinks: [DrinkWatch] = []
    @Published private(set) var standardDrinkCount: Double = 0.0
    @Published private(set) var drinkLimit: Double = 4.0
    @Published private(set) var timeUntilReset: TimeInterval = 0
    @Published private(set) var lastSyncTime: Date = Date()
    
    // User settings
    @Published private(set) var userWeight: Double = 160.0
    @Published private(set) var userGender: Gender = .male
    
    // Timer for updating the time until reset
    private var resetTimer: Timer?
    
    private init() {
        loadLocalData()
        startResetTimer()
    }
    
    deinit {
        resetTimer?.invalidate()
    }
    
    // MARK: - Data Management
    
    // Add drink from watch
    func addDrink(type: DrinkType, size: Double, alcoholPercentage: Double) {
        let newDrink = DrinkWatch(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage,
            timestamp: Date()
        )
        
        drinks.append(newDrink)
        calculateDrinkCount()
        saveLocalData()
        
        // Send new drink to phone
        WatchSessionManager.shared.sendDrinkToPhone(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage
        )
    }
    
    // Quick add standard drink of given type
    func quickAddDrink(type: DrinkType) {
        addDrink(
            type: type,
            size: type.defaultSize,
            alcoholPercentage: type.defaultAlcoholPercentage
        )
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.success)
    }
    
    // Update data from phone sync
    func updateFromPhoneData(drinkCount: Double, drinkLimit: Double, timeUntilReset: TimeInterval) {
        self.standardDrinkCount = drinkCount
        self.drinkLimit = drinkLimit
        self.timeUntilReset = timeUntilReset
        self.lastSyncTime = Date()
        
        saveLocalData()
    }
    
    // Update user profile from phone
    func updateUserProfile(weight: Double, gender: Gender) {
        self.userWeight = weight
        self.userGender = gender
        saveLocalData()
    }
    
    // MARK: - Helper Methods
    
    private func startResetTimer() {
        // Update every minute to recalculate time until reset
        resetTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeUntilReset()
        }
    }
    
    private func updateTimeUntilReset() {
        // Decrement time until reset
        if timeUntilReset > 60 {
            timeUntilReset -= 60
            saveLocalData()
        } else {
            // Reset time passed, request fresh data from phone
            WatchSessionManager.shared.requestDrinkDataFromPhone()
        }
    }
    
    private func calculateDrinkCount() {
        // Filter recent drinks (last 24 hours)
        let recentDrinks = drinks.filter {
            Calendar.current.dateComponents([.hour], from: $0.timestamp, to: Date()).hour! < 24
        }
        
        // Add up standard drinks
        standardDrinkCount = recentDrinks.reduce(0) { $0 + $1.standardDrinks }
    }
    
    // MARK: - Persistence Methods
    
    private func saveLocalData() {
        // Save current state to UserDefaults
        UserDefaults.standard.set(standardDrinkCount, forKey: "watchDrinkCount")
        UserDefaults.standard.set(drinkLimit, forKey: "watchDrinkLimit")
        UserDefaults.standard.set(timeUntilReset, forKey: "watchTimeUntilReset")
        UserDefaults.standard.set(Date(), forKey: "watchLastSyncTime")
        UserDefaults.standard.set(userWeight, forKey: "watchUserWeight")
        UserDefaults.standard.set(userGender.rawValue, forKey: "watchUserGender")
        
        // Save drinks array
        if let encodedDrinks = try? JSONEncoder().encode(drinks) {
            UserDefaults.standard.set(encodedDrinks, forKey: "watchSavedDrinks")
        }
    }
    
    private func loadLocalData() {
        // Load data from UserDefaults
        standardDrinkCount = UserDefaults.standard.double(forKey: "watchDrinkCount")
        
        let savedLimit = UserDefaults.standard.double(forKey: "watchDrinkLimit")
        drinkLimit = savedLimit > 0 ? savedLimit : 4.0
        
        timeUntilReset = UserDefaults.standard.double(forKey: "watchTimeUntilReset")
        
        let savedWeight = UserDefaults.standard.double(forKey: "watchUserWeight")
        userWeight = savedWeight > 0 ? savedWeight : 160.0
        
        if let genderString = UserDefaults.standard.string(forKey: "watchUserGender"),
           let gender = Gender(rawValue: genderString) {
            userGender = gender
        }
        
        // Load saved drinks
        if let savedDrinks = UserDefaults.standard.data(forKey: "watchSavedDrinks"),
           let decodedDrinks = try? JSONDecoder().decode([DrinkWatch].self, from: savedDrinks) {
            drinks = decodedDrinks
        }
    }
    
    // MARK: - Status Methods
    
    func getSafetyStatus() -> SafetyStatus {
        if standardDrinkCount >= drinkLimit {
            return .unsafe
        } else if standardDrinkCount >= drinkLimit * 0.75 {
            return .borderline
        } else {
            return .safe
        }
    }
    
    func getFormattedTimeUntilReset() -> String {
        let hours = Int(timeUntilReset) / 3600
        let minutes = (Int(timeUntilReset) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func formatTimeSinceSync() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSyncTime, relativeTo: Date())
    }
}

// MARK: - Watch Drink Model
struct DrinkWatch: Identifiable, Codable, Hashable {
    let id: UUID
    let type: DrinkType
    let size: Double
    let alcoholPercentage: Double
    let timestamp: Date
    
    init(type: DrinkType, size: Double, alcoholPercentage: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.size = size
        self.alcoholPercentage = alcoholPercentage
        self.timestamp = timestamp
    }
    
    var standardDrinks: Double {
        let pureAlcohol = size * (alcoholPercentage / 100)
        return pureAlcohol / 0.6
    }
}
