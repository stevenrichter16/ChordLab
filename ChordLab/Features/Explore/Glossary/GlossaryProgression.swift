//
//  GlossaryProgression.swift
//  ChordLab
//
//  Model for the built-in glossary of famous chord progressions.
//  Entries are degree-based so every progression renders and plays
//  in the user's current key.
//

import Foundation
import SwiftUI
import Tonic

struct GlossaryProgression: Identifiable {
    let id: String                 // stable identifier
    let name: String               // "The Axis of Awesome"
    let numerals: String           // display line, e.g. "I – V – vi – IV"
    let details: String            // where it's heard / why it works
    let category: GlossaryCategory
    let degrees: [GlossaryChordSpec]
    let suggestedTempo: Int?       // nil = keep the user's tempo

    init(
        id: String,
        name: String,
        numerals: String,
        details: String,
        category: GlossaryCategory,
        degrees: [GlossaryChordSpec],
        suggestedTempo: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.numerals = numerals
        self.details = details
        self.category = category
        self.degrees = degrees
        self.suggestedTempo = suggestedTempo
    }

    /// Renders the entry into playable chords in the engine's current key.
    /// Returns [] if diatonic analysis is unavailable.
    func playbackChords(in engine: TheoryEngine) -> [TheoryEngine.PlaybackChord] {
        let triads = engine.getDiatonicChordsWithAnalysis()
        let sevenths = engine.getSeventhChordsWithAnalysis()
        guard triads.count == 7, sevenths.count == 7 else { return [] }

        return degrees.compactMap { spec in
            guard (0..<7).contains(spec.degreeIndex) else { return nil }
            let entry = spec.seventh ? sevenths[spec.degreeIndex] : triads[spec.degreeIndex]
            return TheoryEngine.PlaybackChord(chord: entry.chord, duration: spec.beats)
        }
    }

    /// (symbol, numeral) pairs for the chip row, in the engine's current key
    func chipData(in engine: TheoryEngine) -> [(symbol: String, numeral: String)] {
        let triads = engine.getDiatonicChordsWithAnalysis()
        let sevenths = engine.getSeventhChordsWithAnalysis()
        guard triads.count == 7, sevenths.count == 7 else { return [] }

        return degrees.compactMap { spec in
            guard (0..<7).contains(spec.degreeIndex) else { return nil }
            let entry = spec.seventh ? sevenths[spec.degreeIndex] : triads[spec.degreeIndex]
            return (entry.chord.formattedSymbol, entry.romanNumeral)
        }
    }
}

struct GlossaryChordSpec {
    let degreeIndex: Int   // 0...6 (I through vii°)
    let seventh: Bool      // use the diatonic seventh chord instead of the triad
    let beats: Double      // 1, 2, or 4

    init(_ degreeIndex: Int, seventh: Bool = false, beats: Double = 2) {
        self.degreeIndex = degreeIndex
        self.seventh = seventh
        self.beats = beats
    }
}

enum GlossaryCategory: String, CaseIterable, Identifiable {
    case pop = "Pop"
    case rock = "Rock"
    case jazz = "Jazz"
    case classical = "Classical"
    case blues = "Blues"
    case cadences = "Cadences"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pop: return "star.fill"
        case .rock: return "bolt.fill"
        case .jazz: return "moon.stars.fill"
        case .classical: return "building.columns.fill"
        case .blues: return "guitars.fill"
        case .cadences: return "flag.checkered"
        }
    }

    var tint: Color {
        switch self {
        case .pop: return .pink
        case .rock: return .orange
        case .jazz: return .indigo
        case .classical: return .brown
        case .blues: return .blue
        case .cadences: return .green
        }
    }
}
