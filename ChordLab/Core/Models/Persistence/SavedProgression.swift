//
//  SavedProgression.swift
//  ChordLab
//
//  User-created chord progressions
//

import Foundation
import SwiftData

@Model
final class SavedProgression {
    var id: UUID = UUID()
    var name: String
    var dateCreated: Date = Date()
    var dateModified: Date = Date()
    var key: String
    var scale: String = "major"
    var tempo: Int = 120
    var timeSignature: String = "4/4"
    
    // Legacy fields for backward compatibility
    var chords: [String] = []
    var romanNumerals: [String] = []
    
    // New enhanced chord data
    var progressionChordsData: Data? // JSON encoded [ProgressionChord]
    
    // User interaction data
    var tags: [String] = []
    var isFavorite: Bool = false
    var playCount: Int = 0
    var lastPlayedAt: Date?
    var notes: String?
    
    // Calculated properties
    var duration: TimeInterval = 0 // Total duration in seconds
    
    // Future extensibility
    var metadata: Data? // JSON encoded [String: String]
    var analysisCache: Data? // Cached analysis results
    
    // Computed property for chord count
    var chordCount: Int {
        if let data = progressionChordsData,
           let chords = try? JSONDecoder().decode([ProgressionChord].self, from: data) {
            return chords.count
        }
        return chords.count // Fallback to legacy
    }
    
    // Computed property to get ProgressionChord array
    var progressionChords: [ProgressionChord] {
        get {
            if let data = progressionChordsData,
               let chords = try? JSONDecoder().decode([ProgressionChord].self, from: data) {
                return chords
            }
            // Fallback to legacy data
            return chords.enumerated().map { index, chord in
                ProgressionChord(
                    chordSymbol: chord,
                    romanNumeral: index < romanNumerals.count ? romanNumerals[index] : "",
                    duration: 1.0
                )
            }
        }
        set {
            progressionChordsData = try? JSONEncoder().encode(newValue)
            // Update duration
            duration = calculateDuration(chords: newValue, tempo: tempo)
        }
    }
    
    init(name: String, chords: [String], key: String, scale: String = "major", tempo: Int = 120) {
        self.id = UUID()
        self.name = name
        self.chords = chords
        self.key = key
        self.scale = scale
        self.tempo = tempo
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    // New initializer with ProgressionChord support
    init(name: String, progressionChords: [ProgressionChord], key: String, scale: String = "major", tempo: Int = 120) {
        self.id = UUID()
        self.name = name
        self.key = key
        self.scale = scale
        self.tempo = tempo
        self.dateCreated = Date()
        self.dateModified = Date()
        self.progressionChords = progressionChords
        
        // Also populate legacy fields for compatibility
        self.chords = progressionChords.map { $0.chordSymbol }
        self.romanNumerals = progressionChords.map { $0.romanNumeral }
    }
    
    private func calculateDuration(chords: [ProgressionChord], tempo: Int) -> TimeInterval {
        let totalBeats = chords.reduce(0) { $0 + $1.duration }
        let beatsPerSecond = Double(tempo) / 60.0
        return totalBeats / beatsPerSecond
    }
}