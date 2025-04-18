//
//  Configuration.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Config/Configuration.swift

import Foundation

// MARK: - App Configuration
struct Configuration {
    // App bundle info
    static let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "BarBuddy Watch+"
    static let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    static let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    
    // Deep link configuration
    static let appScheme = "barbuddy://"
    
    // Color scheme identifiers
    struct ColorKeys {
        static let accent = "AccentColor"
        static let beerColor = "BeerColor"
        static let wineColor = "WineColor"
        static let cocktailColor = "CocktailColor"
        static let shotColor = "ShotColor"
    }
    
    // Health Kit integration settings
    struct HealthKit {
        static let enabled = true
        static let waterTrackingEnabled = true
    }
    
    // Notification default settings
    struct Notifications {
        static let hydrationReminderInterval: TimeInterval = 30 * 60 // 30 minutes
        static let drinkingDurationAlertTime: TimeInterval = 3 * 60 * 60 // 3 hours
        static let drinkLimitExceededCategory = "DRINKING_LIMIT"
        static let hydrationReminderCategory = "HYDRATION_REMINDER"
    }
    
    // Complication settings
    struct Complications {
        static let mainComplicationIdentifier = "com.barbuddy.drinking"
        static let updateInterval: TimeInterval = 15 * 60 // 15 minutes
    }
    
    // Watch app limits
    struct AppLimits {
        static let maxStandardDrinks: Double = 20.0
        static let maxStoredDrinks = 100
        static let maxDrinkLimit: Double = 10.0
    }
    
    // Debug settings
    struct Debug {
        #if DEBUG
        static let loggingEnabled = true
        static let mockDataEnabled = true
        #else
        static let loggingEnabled = false
        static let mockDataEnabled = false
        #endif
    }
}

// MARK: - Debug Logger
struct Log {
    enum Level: String {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case debug = "DEBUG"
    }
    
    static func print(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if Configuration.Debug.loggingEnabled {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            Swift.print("[\(level.rawValue)] [\(fileName):\(line)] \(function): \(message)")
        }
        #endif
    }
}

// MARK: - Mock Data Provider
struct MockData {
    static var drinks: [DrinkWatch] {
        guard Configuration.Debug.mockDataEnabled else { return [] }
        
        return [
            DrinkWatch(type: .beer, size: 12.0, alcoholPercentage: 5.0, timestamp: Date().addingTimeInterval(-30 * 60)),
            DrinkWatch(type: .wine, size: 5.0, alcoholPercentage: 12.0, timestamp: Date().addingTimeInterval(-70 * 60)),
            DrinkWatch(type: .shot, size: 1.5, alcoholPercentage: 40.0, timestamp: Date().addingTimeInterval(-100 * 60))
        ]
    }
    
    static var standardDrinkCount: Double {
        return 2.5
    }
    
    static var drinkLimit: Double {
        return 4.0
    }
    
    static var timeUntilReset: TimeInterval {
        return 8 * 60 * 60 // 8 hours
    }
}
