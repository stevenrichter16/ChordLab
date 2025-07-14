//
//  ProgressionChord.swift
//  ChordLab
//
//  Represents a single chord in a saved progression with full metadata
//

import Foundation

struct ProgressionChord: Codable, Equatable {
    let chordSymbol: String      // e.g., "Cmaj7"
    let romanNumeral: String     // e.g., "I"
    let noteNames: [String]      // e.g., ["C", "E", "G", "B"]
    let function: String         // e.g., "Tonic"
    let duration: Double         // In beats (default 1.0)
    let selectedFromKey: String? // The key the chord was selected from (e.g., "C")
    let keysContaining: [String] // All keys that contain this chord
    
    init(
        chordSymbol: String,
        romanNumeral: String = "",
        noteNames: [String] = [],
        function: String = "",
        duration: Double = 1.0,
        selectedFromKey: String? = nil,
        keysContaining: [String] = []
    ) {
        self.chordSymbol = chordSymbol
        self.romanNumeral = romanNumeral
        self.noteNames = noteNames
        self.function = function
        self.duration = duration
        self.selectedFromKey = selectedFromKey
        self.keysContaining = keysContaining
    }
}

extension ProgressionChord {
    // Convert to/from JSON for SwiftData storage
    var jsonData: Data? {
        try? JSONEncoder().encode(self)
    }
    
    static func from(jsonData: Data) -> ProgressionChord? {
        try? JSONDecoder().decode(ProgressionChord.self, from: jsonData)
    }
}