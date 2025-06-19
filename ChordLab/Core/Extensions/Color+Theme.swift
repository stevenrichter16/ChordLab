//
//  Color+Theme.swift
//  ChordLab
//
//  App color theme and extensions
//

import SwiftUI

extension Color {
    // MARK: - App Theme Colors
    
    static let appPrimary = Color.blue
    static let appSecondary = Color.purple
    static let appAccent = Color.orange
    
    // MARK: - Semantic Colors
    
    static let cardBackground = Color(.systemBackground)
    static let cardForeground = Color(.label)
    static let subtleBackground = Color(.secondarySystemBackground)
    
    // MARK: - App Background Colors
    
    static let appBackground = Color(.systemGroupedBackground)
    static let appSecondaryBackground = Color(.secondarySystemGroupedBackground)
    static let appTertiaryBackground = Color(.tertiarySystemGroupedBackground)
    
    // MARK: - Music Theory Colors
    
    static let tonicColor = Color.green
    static let subdominantColor = Color.blue
    static let dominantColor = Color.red
    static let chromaticColor = Color.orange
    static let borrowedColor = Color.purple
    
    // MARK: - Piano Key Colors
    
    static let whiteKeyColor = Color.white
    static let blackKeyColor = Color.black
    //static let highlightedKeyColor = Color.blue.opacity(0.7)
    //static let rootNoteColor = Color.red.opacity(0.8)
    
    // MARK: - Achievement Colors
    
    static let bronzeColor = Color(red: 0.80, green: 0.50, blue: 0.20)
    static let silverColor = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let goldColor = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let platinumColor = Color(red: 0.90, green: 0.90, blue: 0.95)
    
    // MARK: - Gradient Definitions
    
    static let primaryGradient = LinearGradient(
        colors: [appPrimary, appSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color.green, Color.mint],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let warningGradient = LinearGradient(
        colors: [Color.orange, Color.yellow],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - View Extensions for Theme

extension View {
    /// Apply primary app styling to a view
    func primaryStyle() -> some View {
        self    
            .foregroundColor(.appPrimary)
            .font(.headline)
    }
    
    /// Apply card styling
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    /// Apply subtle background styling
    func subtleBackground() -> some View {
        self
            .background(Color.subtleBackground)
            .cornerRadius(8)
    }
}

//
//  Color+PianoKeys.swift
//  ChordLab
//
//  Color extensions for piano key highlighting
//

import SwiftUI

extension Color {
    // Piano key specific colors
    static let highlightedKeyColor = Color.blue.opacity(0.6)
    static let rootNoteColor = Color.orange
    
    // Helper to create darker versions of colors
    func darker(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    // Helper to create lighter versions of colors
    func lighter(by percentage: Double = 0.2) -> Color {
        return self.opacity(1.0 + percentage)
    }
}
