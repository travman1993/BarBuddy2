//
//  DrinkDetailsView.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Views/DrinkDetailsView.swift

import SwiftUI

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
                        .foregroundColor(statusColor)
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
                
                // Safety status
                HStack {
                    Text("Status:")
                    Spacer()
                    Text(drinkTracker.getSafetyStatus().rawValue)
                        .foregroundColor(statusColor)
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
                
                // Recent drinks summary
                if !drinkTracker.drinks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Drink:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let lastDrink = drinkTracker.drinks.first {
                            HStack {
                                Text(lastDrink.type.icon)
                                Text(lastDrink.type.rawValue)
                                    .font(.caption2)
                                Spacer()
                                Text(formatTimeSince(lastDrink.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Last sync time
                Text("Last synced: \(drinkTracker.formatTimeSinceSync())")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                
                // Action button
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding()
        }
    }
    
    private var statusColor: Color {
        switch drinkTracker.getSafetyStatus() {
        case .safe: return .green
        case .borderline: return .yellow
        case .unsafe: return .red
        }
    }
    
    private func formatTimeSince(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
struct DrinkDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkDetailsView()
            .environmentObject(DrinkTrackerWatch.shared)
    }
}
#endif
