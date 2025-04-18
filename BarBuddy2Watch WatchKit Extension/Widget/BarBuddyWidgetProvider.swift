//
//  BarBuddyWidgetProvider.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Widget/BarBuddyWidgetProvider.swift

import WidgetKit
import SwiftUI

// MARK: - Widget Provider
struct BarBuddyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DrinkStatusEntry {
        DrinkStatusEntry(date: Date(), count: 2.0, limit: 4.0, status: .safe)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DrinkStatusEntry) -> Void) {
        // Get current data from drink tracker
        let count = DrinkTrackerWatch.shared.standardDrinkCount
        let limit = DrinkTrackerWatch.shared.drinkLimit
        let status = DrinkTrackerWatch.shared.getSafetyStatus()
        let entry = DrinkStatusEntry(date: Date(), count: count, limit: limit, status: status)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DrinkStatusEntry>) -> Void) {
        // Get current data
        let count = DrinkTrackerWatch.shared.standardDrinkCount
        let limit = DrinkTrackerWatch.shared.drinkLimit
        let status = DrinkTrackerWatch.shared.getSafetyStatus()
        
        // Create entry with current data
        let currentEntry = DrinkStatusEntry(date: Date(), count: count, limit: limit, status: status)
        
        // Create a timeline with refresh every 30 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [currentEntry], policy: .after(refreshDate))
        
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct DrinkStatusEntry: TimelineEntry {
    let date: Date
    let count: Double
    let limit: Double
    let status: SafetyStatus
    
    var percentage: Double {
        return min(count / limit, 1.0)
    }
}

// MARK: - Widget View
struct BarBuddyWidgetEntryView: View {
    var entry: DrinkStatusEntry
    @Environment(\.widgetFamily) var family
    
    var statusColor: Color {
        switch entry.status {
        case .safe: return .green
        case .borderline: return .yellow
        case .unsafe: return .red
        }
    }
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        case .accessoryCorner:
            CornerWidgetView(entry: entry)
        default:
            // Default view for other sizes
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .padding(4)
                
                Circle()
                    .trim(from: 0, to: CGFloat(entry.percentage))
                    .stroke(statusColor, style: StrokeStyle(lineWidth: a8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(4)
                
                VStack {
                    Text("\(String(format: "%.1f", entry.count))")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(statusColor)
                    
                    Text("/\(String(format: "%.1f", entry.limit))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Circular Widget View
struct CircularWidgetView: View {
    var entry: DrinkStatusEntry
    
    var body: some View {
        Gauge(value: entry.percentage) {
            Image(systemName: "wineglass")
                .font(.system(size: 10))
        } currentValueLabel: {
            Text("\(Int(entry.count))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(entry.status.color)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.status.color)
    }
}

// MARK: - Rectangular Widget View
struct RectangularWidgetView: View {
    var entry: DrinkStatusEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "wineglass")
                    .font(.body)
                
                Text("Drinks")
                    .font(.caption2)
                
                Spacer()
                
                Text("\(String(format: "%.1f", entry.count))/\(String(format: "%.1f", entry.limit))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.status.color)
            }
            
            Gauge(value: entry.percentage) {
                EmptyView()
            }
            .tint(entry.status.color)
            .gaugeStyle(.accessoryLinear)
            
            Text(entry.status.rawValue)
                .font(.caption2)
                .foregroundColor(entry.status.color)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Corner Widget View
struct CornerWidgetView: View {
    var entry: DrinkStatusEntry
    
    var body: some View {
        Gauge(value: entry.percentage) {
            Text("Drinks")
                .font(.system(size: 10))
        } currentValueLabel: {
            Text("\(String(format: "%.1f", entry.count))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(entry.status.color)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.status.color)
    }
}

// MARK: - Widget Configuration
struct BarBuddyWidget: Widget {
    let kind: String = "rodriguez.travis.BarBuddy2.widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BarBuddyWidgetProvider()) { entry in
            BarBuddyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Drink Status")
        .description("Shows your current drink count and status.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner])
    }
}

// MARK: - Widget Preview
struct BarBuddyWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BarBuddyWidgetEntryView(
                entry: DrinkStatusEntry(
                    date: Date(),
                    count: 2.5,
                    limit: 4.0,
                    status: .safe
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")
            
            BarBuddyWidgetEntryView(
                entry: DrinkStatusEntry(
                    date: Date(),
                    count: 3.5,
                    limit: 4.0,
                    status: .borderline
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            .previewDisplayName("Rectangular")
            
            BarBuddyWidgetEntryView(
                entry: DrinkStatusEntry(
                    date: Date(),
                    count: 4.5,
                    limit: 4.0,
                    status: .unsafe
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            .previewDisplayName("Corner")
        }
    }
}
