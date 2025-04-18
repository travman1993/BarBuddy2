//
//  ComplicationController.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/ComplicationController.swift

import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "com.barbuddy.drinking",
                displayName: "Drink Tracker",
                supportedFamilies: [
                    .modularSmall,
                    .modularLarge,
                    .circularSmall,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular,
                    .graphicExtraLarge
                ]
            )
        ]
        
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Calculate when next reset time will be (4 AM)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 4
        components.minute = 0
        components.second = 0
        
        var resetDate = calendar.date(from: components)!
        
        // If current time is past 4 AM, use tomorrow's 4 AM
        if Date() >= resetDate {
            resetDate = calendar.date(byAdding: .day, value: 1, to: resetDate)!
        }
        
        handler(resetDate)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Use .showOnLockScreen to show this complication on the lock screen
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Get the current data from DrinkTrackerWatch
        let drinkCount = DrinkTrackerWatch.shared.standardDrinkCount
        let drinkLimit = DrinkTrackerWatch.shared.drinkLimit
        let safetyStatus = DrinkTrackerWatch.shared.getSafetyStatus()
        
        // Create a template based on the complication family
        let template = createTemplate(for: complication.family,
                                     count: drinkCount,
                                     limit: drinkLimit,
                                     status: safetyStatus)
        
        // If the template is valid, create a timeline entry
        if let template = template {
            let entry = CLKComplicationTimelineEntry(
                date: Date(),
                complicationTemplate: template
            )
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with nil to indicate future timeline entries can't be predicted
        handler(nil)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // Create a template with sample data
        let template = createTemplate(for: complication.family,
                                     count: 2.5,
                                     limit: 4.0,
                                     status: .safe)
        
        handler(template)
    }
    
    // MARK: - Private Methods
    
    private func createTemplate(for family: CLKComplicationFamily, count: Double, limit: Double, status: SafetyStatus) -> CLKComplicationTemplate? {
        // Format the drink count as a string
        let drinkCountText = String(format: "%.1f", count)
        let limitText = String(format: "%.1f", limit)
        let percentage = Float(min(count / limit, 1.0))
        
        // Determine the color based on status
        let color: UIColor
        switch status {
        case .safe:
            color = UIColor.green
        case .borderline:
            color = UIColor.yellow
        case .unsafe:
            color = UIColor.red
        }
        
        // Create a template based on the complication family
        switch family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "Drinks")
            template.line2TextProvider = CLKSimpleTextProvider(text: drinkCountText, shortText: drinkCountText)
            template.line2TextProvider.tintColor = color
            return template
            
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "BarBuddy")
            template.body1TextProvider = CLKSimpleTextProvider(text: "Drinks: \(drinkCountText)/\(limitText)")
            template.body1TextProvider.tintColor = color
            template.body2TextProvider = CLKSimpleTextProvider(text: status.rawValue)
            return template
            
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: drinkCountText)
            template.fillFraction = percentage
            template.ringStyle = .closed
            template.tintColor = color
            return template
            
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
            template.centerTextProvider = CLKSimpleTextProvider(text: drinkCountText)
            template.bottomTextProvider = CLKSimpleTextProvider(text: "")
            template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: color, fillFraction: percentage)
            return template
            
        case .graphicCorner:
            let template = CLKComplicationTemplateGraphicCornerGaugeText()
            template.outerTextProvider = CLKSimpleTextProvider(text: "Drinks")
            template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: color, fillFraction: percentage)
            template.innerTextProvider = CLKSimpleTextProvider(text: drinkCountText)
            return template
            
        case .graphicRectangular:
            let template = CLKComplicationTemplateGraphicRectangularTextGauge()
            template.headerTextProvider = CLKSimpleTextProvider(text: "BarBuddy")
            template.body1TextProvider = CLKSimpleTextProvider(text: "Drinks: \(drinkCountText)/\(limitText)")
            template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: color, fillFraction: percentage)
            return template
            
        case .graphicExtraLarge:
            if #available(watchOS 7.0, *) {
                let template = CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText()
                template.centerTextProvider = CLKSimpleTextProvider(text: drinkCountText)
                template.bottomTextProvider = CLKSimpleTextProvider(text: "")
                template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: color, fillFraction: percentage)
                return template
            }
            return nil
            
        default:
            return nil
        }
    }
}
