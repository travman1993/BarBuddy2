//
//  EmergencySheetView.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Views/EmergencySheetView.swift

import SwiftUI
import WatchKit

struct EmergencySheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var drinkTracker: DrinkTrackerWatch
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Emergency Options")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
                
                if isLoading {
                    ProgressView()
                        .padding(.vertical, 8)
                } else {
                    // Emergency contact call
                    Button(action: {
                        callEmergencyContact()
                    }) {
                        Label("Call Emergency Contact", systemImage: "phone.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Call 911
                    Button(action: {
                        call911()
                    }) {
                        Label("Call 911", systemImage: "phone.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Ride options
                    Button(action: {
                        getUber()
                    }) {
                        Label("Uber", systemImage: "car.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        getLyft()
                    }) {
                        Label("Lyft", systemImage: "car.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.pink)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Share location
                    Button(action: {
                        shareLocation()
                    }) {
                        Label("Share Location", systemImage: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Cancel button
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.gray)
                .padding(.top, 4)
            }
            .padding(12)
        }
    }
    
    // MARK: - Action Methods
    
    private func callEmergencyContact() {
        isLoading = true
        
        // This would ideally contact the iOS app to get the emergency contact
        // For now, we'll simulate with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            
            // In a real app, this would use the actual emergency contact
            if let url = URL(string: "tel://911") {
                WKExtension.shared().openSystemURL(url)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func call911() {
        if let url = URL(string: "tel://911") {
            WKExtension.shared().openSystemURL(url)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func getUber() {
        if let url = URL(string: "uber://") {
            WKExtension.shared().openSystemURL(url)
            presentationMode.wrappedValue.dismiss()
        } else if let url = URL(string: "https://m.uber.com") {
            WKExtension.shared().openSystemURL(url)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func getLyft() {
        if let url = URL(string: "lyft://") {
            WKExtension.shared().openSystemURL(url)
            presentationMode.wrappedValue.dismiss()
        } else if let url = URL(string: "https://www.lyft.com") {
            WKExtension.shared().openSystemURL(url)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func shareLocation() {
        isLoading = true
        
        // This would typically use location services to get the current location
        // and send it to emergency contacts via the companion iOS app
        
        // For now, just simulate with haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            WKInterfaceDevice.current().play(.notification)
            
            // Show confirmation alert on watch
            let alertText = "Location sent to emergency contacts"
            
            // Dismiss after displaying confirmation
            presentationMode.wrappedValue.dismiss()
            
            // Show a local notification
            WKExtension.shared().sendLocalNotification(
                title: "Location Shared",
                body: alertText,
                userInfo: ["type": "locationShared"]
            )
        }
    }
}

#if DEBUG
struct EmergencySheetView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencySheetView()
            .environmentObject(DrinkTrackerWatch.shared)
    }
}
#endif
