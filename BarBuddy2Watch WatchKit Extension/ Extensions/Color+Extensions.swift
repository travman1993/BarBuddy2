//
//  Color+Extensions.swift
//  BarBuddy2
//
//  Created by Travis Rodriguez on 4/17/25.
//
// BarBuddy2Watch WatchKit Extension/Extensions/Color+Extensions.swift

import SwiftUI

extension Color {
    // App theme colors
    static let accent = Color("AccentColor")
    static let warning = Color.yellow
    static let danger = Color.red
    static let safe = Color.green
    
    // Background colors
    static let appBackground = Color.black
    static let appCardBackground = Color.black.opacity(0.7)
    
    // Text colors
    static let appTextPrimary = Color.white
    static let appTextSecondary = Color.gray
    
    // Drink type colors
    static let beerColor = Color(red: 0.85, green: 0.65, blue: 0.13) // Amber
    static let wineColor = Color(red: 0.7, green: 0.1, blue: 0.3) // Burgundy
    static let cocktailColor = Color(red: 0.0, green: 0.6, blue: 0.8) // Blue
    static let shotColor = Color(red: 0.5, green: 0.2, blue: 0.7) // Purple
}

// Extended for SafetyStatus colors
extension SafetyStatus {
    var color: Color {
        switch self {
        case .safe: return .safe
        case .borderline: return .warning
        case .unsafe: return .danger
        }
    }
}

// Extended for DrinkType colors
extension DrinkType {
    var color: Color {
        switch self {
        case .beer: return .beerColor
        case .wine: return .wineColor
        case .cocktail: return .cocktailColor
        case .shot: return .shotColor
        case .other: return Color.appTextSecondary
        }
    }
}
