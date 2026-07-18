//
//  DesignSystem.swift
//  ChordLab
//
//  App-wide design tokens: shape, spacing, elevation, motion, and the
//  fixed-size "instrument chrome" type styles. Reading text uses semantic
//  Dynamic Type styles; these tokens exist for everything else so the
//  numbers live in one place.
//

import SwiftUI

// MARK: - Shape

/// Corner radius scale. Three stops only:
/// chips and small controls, cards and cells, floating chrome.
enum AppRadius {
    static let chip: CGFloat = 8
    static let card: CGFloat = 12
    static let chrome: CGFloat = 20
}

// MARK: - Spacing

/// 4pt spacing grid
enum AppSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Motion

extension Animation {
    /// The house spring — every interactive state change uses this
    static let appSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)

    /// Slightly softer spring for large surfaces (dock expansion, sheets)
    static let appSpringSlow = Animation.spring(response: 0.35, dampingFraction: 0.85)
}

// MARK: - Elevation

/// Resting elevation for cards and rows
private struct CardShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(
            color: .black.opacity(colorScheme == .dark ? 0.30 : 0.08),
            radius: 4,
            y: 2
        )
    }
}

/// Floating elevation for chrome that sits over content (dock, popovers)
private struct FloatingShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(
            color: .black.opacity(colorScheme == .dark ? 0.45 : 0.16),
            radius: 12,
            y: 4
        )
    }
}

extension View {
    /// Resting elevation for cards and rows (scheme-aware opacity)
    func cardShadow() -> some View {
        modifier(CardShadow())
    }

    /// Floating elevation for chrome hovering over content (scheme-aware)
    func floatingShadow() -> some View {
        modifier(FloatingShadow())
    }
}

// MARK: - Instrument chrome type

/// Fixed-size type is reserved for musical chrome — chord symbols on
/// cells, countdowns, readouts — where layout is width-critical and the
/// glyphs act as UI, not prose. Everything else uses Dynamic Type.
extension Font {
    /// Chord symbol on a timeline cell or chip
    static let chordSymbol = Font.system(size: 16, weight: .semibold)

    /// Chord symbol in compact contexts (suggestion chips, glossary chips)
    static let chordSymbolSmall = Font.system(size: 14, weight: .semibold)

    /// The count-in numeral over the timeline
    static let countdown = Font.system(size: 44, weight: .bold, design: .rounded)

    /// Monospaced readouts: progression string, BPM, count-in caption
    static let monoReadout = Font.system(size: 14, weight: .medium, design: .monospaced)
}
