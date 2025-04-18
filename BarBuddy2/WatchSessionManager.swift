//
//  WatchSessionManager.swift
//  BarBuddy2

import Foundation
import WatchConnectivity

/**
 * Manages communication between the iOS app and Apple Watch app.
 *
 * This class handles sending drink data, and user profile information
 * to the companion Watch app, and processes requests from the Watch.
 */
class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    /// Shared singleton instance
    static let shared = WatchSessionManager()
    
    /// Published properties for tracking session state
    @Published var isReachable = false
    @Published var isWatchAppInstalled = false
    @Published var watchLastSync: Date?
    
    /// Session reference
    private var session: WCSession?
    
    /// Drink tracker reference (weak to avoid retain cycle)
    private weak var drinkTracker: DrinkTracker?
    
    /**
     * Initializes the Watch Session Manager.
     */
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    /**
     * Sets up the Watch Connectivity session.
     */
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    /**
     * Sets the drink tracker reference to enable data sharing.
     *
     * - Parameter tracker: The app's DrinkTracker instance
     */
    func setDrinkTracker(_ tracker: DrinkTracker) {
        self.drinkTracker = tracker
    }
    
    /**
     * Sends drink data to the Watch app.
     *
     * - Parameters:
     *   - drinkCount: Current standard drink count
     *   - drinkLimit: User's set drink limit
     *   - timeUntilReset: Time until count resets at 4am
     */
    func sendDrinkDataToWatch(drinkCount: Double, drinkLimit: Double, timeUntilReset: TimeInterval) {
        guard let session = session, session.activationState == .activated,
              session.isPaired && session.isWatchAppInstalled else {
            return
        }
        
        let drinkData: [String: Any] = [
            "type": "drinkUpdate",
            "drinkCount": drinkCount,
            "drinkLimit": drinkLimit,
            "timeUntilReset": timeUntilReset,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Try to send message immediately if watch is reachable
        if session.isReachable {
            session.sendMessage(drinkData, replyHandler: nil) { error in
                print("Error sending drink data: \(error.localizedDescription)")
                
                // Fallback to application context if message fails
                try? session.updateApplicationContext(drinkData)
            }
        } else {
            // Use application context for background transfer
            try? session.updateApplicationContext(drinkData)
        }
        
        // Update complication data on the watch if possible
        if session.isComplicationEnabled {
            session.transferCurrentComplicationUserInfo(drinkData)
        }
    }
    
    /**
     * Sends user profile information to the Watch app.
     */
    func sendUserProfileToWatch() {
        guard let drinkTracker = drinkTracker,
              let session = session, session.activationState == .activated,
              session.isPaired && session.isWatchAppInstalled else {
            return
        }
        
        let profileData: [String: Any] = [
            "type": "profileUpdate",
            "weight": drinkTracker.userProfile.weight,
            "gender": drinkTracker.userProfile.gender.rawValue,
            "height": drinkTracker.userProfile.height ?? 0
        ]
        
        // Try to send message immediately if watch is reachable
        if session.isReachable {
            session.sendMessage(profileData, replyHandler: nil) { error in
                print("Error sending profile data: \(error.localizedDescription)")
                
                // Fallback to application context if message fails
                try? session.updateApplicationContext(profileData)
            }
        } else {
            // Use application context for background transfer
            try? session.updateApplicationContext(profileData)
        }
    }
    
    /**
     * Handles incoming messages from the Watch app.
     */
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let request = message["request"] as? String else {
            replyHandler(["error": "Invalid request"])
            return
        }
        
        DispatchQueue.main.async {
            self.watchLastSync = Date()
        }
        
        switch request {
        case "getCurrentDrinkData":
            // Respond with current drink data if available
            guard let drinkTracker = drinkTracker else {
                replyHandler(["error": "Drink tracker not available"])
                return
            }
            
            replyHandler([
                "drinkCount": drinkTracker.standardDrinkCount,
                "drinkLimit": drinkTracker.drinkLimit,
                "timeUntilReset": drinkTracker.timeUntilReset
            ])
            
        case "getUserProfile":
            // Respond with user profile data
            guard let drinkTracker = drinkTracker else {
                replyHandler(["error": "Drink tracker not available"])
                return
            }
            
            replyHandler([
                "weight": drinkTracker.userProfile.weight,
                "gender": drinkTracker.userProfile.gender.rawValue,
                "height": drinkTracker.userProfile.height ?? 0
            ])
            
        case "logDrink":
            // Log a drink from Watch
            guard let drinkTracker = drinkTracker else {
                replyHandler(["error": "Drink tracker not available"])
                return
            }
            
            // Extract drink parameters from message
            guard let drinkType = message["drinkType"] as? String,
                  let type = DrinkType(rawValue: drinkType),
                  let size = message["size"] as? Double,
                  let alcoholPercentage = message["alcoholPercentage"] as? Double else {
                
                // If missing size or percentage, use defaults
                if let drinkType = message["drinkType"] as? String,
                   let type = DrinkType(rawValue: drinkType) {
                    
                    // Add drink using default values from drink type
                    drinkTracker.addDrink(
                        type: type,
                        size: type.defaultSize,
                        alcoholPercentage: type.defaultAlcoholPercentage
                    )
                    
                    // Respond with updated drink data
                    replyHandler([
                        "drinkCount": drinkTracker.standardDrinkCount,
                        "drinkLimit": drinkTracker.drinkLimit,
                        "timeUntilReset": drinkTracker.timeUntilReset
                    ])
                    return
                }
                
                replyHandler(["error": "Invalid drink parameters"])
                return
            }
            
            // Add the drink with specific parameters
            drinkTracker.addDrink(
                type: type,
                size: size,
                alcoholPercentage: alcoholPercentage
            )
            
            // Respond with updated drink data
            replyHandler([
                "drinkCount": drinkTracker.standardDrinkCount,
                "drinkLimit": drinkTracker.drinkLimit,
                "timeUntilReset": drinkTracker.timeUntilReset
            ])
            
        case "clearDrinks":
            // Clear all drinks (emergency reset)
            guard let drinkTracker = drinkTracker else {
                replyHandler(["error": "Drink tracker not available"])
                return
            }
            
            drinkTracker.clearDrinks()
            
            // Respond with updated drink data
            replyHandler([
                "drinkCount": drinkTracker.standardDrinkCount,
                "drinkLimit": drinkTracker.drinkLimit,
                "timeUntilReset": drinkTracker.timeUntilReset
            ])
            
        case "updateDrinkLimit":
            // Update drink limit from watch
            guard let drinkTracker = drinkTracker,
                  let newLimit = message["limit"] as? Double else {
                replyHandler(["error": "Invalid or missing limit value"])
                return
            }
            
            drinkTracker.updateDrinkLimit(newLimit)
            
            // Respond with updated drink data
            replyHandler([
                "drinkCount": drinkTracker.standardDrinkCount,
                "drinkLimit": drinkTracker.drinkLimit,
                "timeUntilReset": drinkTracker.timeUntilReset
            ])
            
        case "getEmergencyContacts":
            // Send emergency contacts to watch
            guard let drinkTracker = drinkTracker else {
                replyHandler(["error": "Drink tracker not available"])
                return
            }
            
            let contacts = drinkTracker.userProfile.emergencyContacts
            
            // Convert contacts to serializable dictionary
            let contactDicts = contacts.map { contact -> [String: Any] in
                return [
                    "id": contact.id.uuidString,
                    "name": contact.name,
                    "phoneNumber": contact.phoneNumber,
                    "relationshipType": contact.relationshipType,
                    "sendAutomaticTexts": contact.sendAutomaticTexts
                ]
            }
            
            replyHandler(["contacts": contactDicts])
            
        default:
            replyHandler(["error": "Unknown request type: \(request)"])
        }
    }
    
    // MARK: - WCSessionDelegate Methods
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = (activationState == .activated) && session.isReachable
            self.isWatchAppInstalled = session.isWatchAppInstalled
            
            // If watch app is installed, send initial data
            if session.isWatchAppInstalled && self.drinkTracker != nil {
                self.sendDrinkDataToWatch(
                    drinkCount: self.drinkTracker!.standardDrinkCount,
                    drinkLimit: self.drinkTracker!.drinkLimit,
                    timeUntilReset: self.drinkTracker!.timeUntilReset
                )
                self.sendUserProfileToWatch()
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            
            // If watch is now reachable, send updates
            if session.isReachable && self.drinkTracker != nil {
                self.sendDrinkDataToWatch(
                    drinkCount: self.drinkTracker!.standardDrinkCount,
                    drinkLimit: self.drinkTracker!.drinkLimit,
                    timeUntilReset: self.drinkTracker!.timeUntilReset
                )
            }
        }
    }
    
    // Handle incoming application context updates (for background updates)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        // Process any data sent from the watch in the background
        if let request = applicationContext["request"] as? String,
           request == "needsUpdate" {
            DispatchQueue.main.async {
                if let drinkTracker = self.drinkTracker {
                    self.sendDrinkDataToWatch(
                        drinkCount: drinkTracker.standardDrinkCount,
                        drinkLimit: drinkTracker.drinkLimit,
                        timeUntilReset: drinkTracker.timeUntilReset
                    )
                }
            }
        }
    }
    
    // iOS-specific delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Watch session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Watch session deactivated")
        session.activate()
    }
    #endif
    
    /**
     * Checks if Watch connectivity is available and session is active.
     *
     * - Returns: True if Watch connectivity is fully operational
     */
    func isWatchConnectivityAvailable() -> Bool {
        return WCSession.isSupported() &&
               session?.activationState == .activated &&
               session?.isReachable == true &&
               session?.isWatchAppInstalled == true
    }
    
    /**
     * Forces an immediate update to the watch.
     * Call this when changes are made in the app that should be reflected on the watch.
     */
    func forceWatchUpdate() {
        guard let drinkTracker = drinkTracker else { return }
        
        sendDrinkDataToWatch(
            drinkCount: drinkTracker.standardDrinkCount,
            drinkLimit: drinkTracker.drinkLimit,
            timeUntilReset: drinkTracker.timeUntilReset
        )
        
        sendUserProfileToWatch()
    }
    
    /**
     * Updates complication data on the watch.
     * Call this to refresh the watch face complications.
     */
    func updateComplications() {
        guard let session = session,
              session.activationState == .activated,
              session.isComplicationEnabled,
              let drinkTracker = drinkTracker else {
            return
        }
        
        let complicationData: [String: Any] = [
            "type": "complicationUpdate",
            "drinkCount": drinkTracker.standardDrinkCount,
            "drinkLimit": drinkTracker.drinkLimit,
            "timeUntilReset": drinkTracker.timeUntilReset,
            "safetyStatus": drinkTracker.getSafetyStatus().rawValue
        ]
        
        session.transferCurrentComplicationUserInfo(complicationData)
    }
}
