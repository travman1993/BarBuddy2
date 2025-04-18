//
//  Untitled.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/WatchSessionManager.swift

import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    // Singleton instance
    static let shared = WatchSessionManager()
    
    // Published properties for UI updates
    @Published var isPhoneAppAvailable = false
    @Published var isCompanionAppInstalled = false
    @Published var connectionState = "Disconnected"
    
    // Session reference
    private var session: WCSession?
    
    private override init() {
        super.init()
    }
    
    // Setup WatchConnectivity session
    func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Data Requests
    
    // Request current drink data from phone
    func requestDrinkDataFromPhone() {
        guard let session = session, session.activationState == .activated,
              session.isCompanionAppInstalled else {
            return
        }
        
        let request = ["request": "getCurrentDrinkData"]
        
        session.sendMessage(request, replyHandler: { response in
            // Handle response from phone
            if let drinkCount = response["drinkCount"] as? Double,
               let drinkLimit = response["drinkLimit"] as? Double,
               let timeUntilReset = response["timeUntilReset"] as? TimeInterval {
                
                // Update local drink tracker with data from phone
                DispatchQueue.main.async {
                    DrinkTrackerWatch.shared.updateFromPhoneData(
                        drinkCount: drinkCount,
                        drinkLimit: drinkLimit,
                        timeUntilReset: timeUntilReset
                    )
                }
            }
        }, errorHandler: { error in
            print("Error requesting drink data: \(error.localizedDescription)")
        })
    }
    
    // Request user profile data from phone
    func requestUserProfileFromPhone() {
        guard let session = session, session.activationState == .activated,
              session.isCompanionAppInstalled else {
            return
        }
        
        let request = ["request": "getUserProfile"]
        
        session.sendMessage(request, replyHandler: { response in
            // Handle response from phone
            if let weight = response["weight"] as? Double,
               let genderString = response["gender"] as? String,
               let gender = Gender(rawValue: genderString) {
                
                // Update local user profile with data from phone
                DispatchQueue.main.async {
                    DrinkTrackerWatch.shared.updateUserProfile(
                        weight: weight,
                        gender: gender
                    )
                }
            }
        }, errorHandler: { error in
            print("Error requesting user profile: \(error.localizedDescription)")
        })
    }
    
    // Send drink data to phone
    func sendDrinkToPhone(type: DrinkType, size: Double, alcoholPercentage: Double) {
        guard let session = session, session.activationState == .activated,
              session.isCompanionAppInstalled else {
            return
        }
        
        let drinkData: [String: Any] = [
            "request": "logDrink",
            "drinkType": type.rawValue,
            "size": size,
            "alcoholPercentage": alcoholPercentage,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(drinkData, replyHandler: { response in
            // Handle updated data from phone after logging drink
            if let drinkCount = response["drinkCount"] as? Double,
               let drinkLimit = response["drinkLimit"] as? Double,
               let timeUntilReset = response["timeUntilReset"] as? TimeInterval {
                
                // Update local drink tracker with updated data from phone
                DispatchQueue.main.async {
                    DrinkTrackerWatch.shared.updateFromPhoneData(
                        drinkCount: drinkCount,
                        drinkLimit: drinkLimit,
                        timeUntilReset: timeUntilReset
                    )
                }
            }
        }, errorHandler: { error in
            print("Error sending drink data: \(error.localizedDescription)")
        })
    }
    
    // MARK: - WCSessionDelegate Methods
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPhoneAppAvailable = session.isReachable
            self.isCompanionAppInstalled = session.isCompanionAppInstalled
            
            switch activationState {
            case .activated:
                self.connectionState = "Connected"
            case .inactive:
                self.connectionState = "Inactive"
            case .notActivated:
                self.connectionState = "Not Activated"
            @unknown default:
                self.connectionState = "Unknown"
            }
        }
        
        // If successfully activated, request initial data
        if activationState == .activated && session.isCompanionAppInstalled {
            requestDrinkDataFromPhone()
            requestUserProfileFromPhone()
        }
    }
    
    // Updated reachability
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneAppAvailable = session.isReachable
            self.connectionState = session.isReachable ? "Connected" : "Phone Unreachable"
        }
    }
    
    // Handle incoming application context updates
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        // Handle data pushed from phone (background updates)
        if let drinkCount = applicationContext["drinkCount"] as? Double,
           let drinkLimit = applicationContext["drinkLimit"] as? Double,
           let timeUntilReset = applicationContext["timeUntilReset"] as? TimeInterval {
            
            DispatchQueue.main.async {
                DrinkTrackerWatch.shared.updateFromPhoneData(
                    drinkCount: drinkCount,
                    drinkLimit: drinkLimit,
                    timeUntilReset: timeUntilReset
                )
            }
        }
    }
    
    // Handle incoming messages from phone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle direct messages from phone (when app is active)
        if let messageType = message["type"] as? String {
            switch messageType {
            case "drinkUpdate":
                if let drinkCount = message["drinkCount"] as? Double,
                   let drinkLimit = message["drinkLimit"] as? Double,
                   let timeUntilReset = message["timeUntilReset"] as? TimeInterval {
                    
                    DispatchQueue.main.async {
                        DrinkTrackerWatch.shared.updateFromPhoneData(
                            drinkCount: drinkCount,
                            drinkLimit: drinkLimit,
                            timeUntilReset: timeUntilReset
                        )
                    }
                }
                
            case "profileUpdate":
                if let weight = message["weight"] as? Double,
                   let genderString = message["gender"] as? String,
                   let gender = Gender(rawValue: genderString) {
                    
                    DispatchQueue.main.async {
                        DrinkTrackerWatch.shared.updateUserProfile(
                            weight: weight,
                            gender: gender
                        )
                    }
                }
                
            default:
                break
            }
        }
    }
}
